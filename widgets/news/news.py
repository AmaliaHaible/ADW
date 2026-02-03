import json
import urllib.request
import urllib.error
import threading
from datetime import datetime, timezone
from pathlib import Path
from PySide6.QtCore import QObject, Property, Signal, Slot, QTimer


class NewsBackend(QObject):
    """Backend for Kagi News widget."""

    categoriesChanged = Signal()
    articlesChanged = Signal()
    isLoadingChanged = Signal()
    errorChanged = Signal()
    selectedCategoriesChanged = Signal()
    activeCategoryChanged = Signal()

    _categoriesFetched = Signal(list)
    _articlesFetched = Signal(str, list, int)
    _fetchError = Signal(str)

    BASE_URL = "https://kite.kagi.com"

    def __init__(self, settings_backend=None, parent=None):
        super().__init__(parent)
        self._settings = settings_backend

        self._categories = []
        self._articles = []
        self._is_loading = False
        self._error = ""
        self._selected_categories = ["tech"]
        self._active_category = "tech"
        self._cache_dir = Path(__file__).parent / "cache"
        self._cache_dir.mkdir(exist_ok=True)

        self._categoriesFetched.connect(self._on_categories_fetched)
        self._articlesFetched.connect(self._on_articles_fetched)
        self._fetchError.connect(self._on_fetch_error)

        self._load_settings()
        self._load_cached_categories()

        if self._selected_categories and self._active_category:
            self._load_cached_articles(self._active_category)

        self._refresh_timer = QTimer(self)
        self._refresh_timer.timeout.connect(self._check_and_refresh)
        self._refresh_timer.start(60 * 1000)

        self._start_background_fetch_categories()

    def _get_todays_cache_date(self):
        """Get the cache date string for today (changes at 12:00 UTC)."""
        now = datetime.now(timezone.utc)
        if now.hour < 12:
            cache_date = now.date().isoformat()
        else:
            cache_date = now.date().isoformat()
        return f"{cache_date}-{'pm' if now.hour >= 12 else 'am'}"

    def _is_cache_valid(self, category):
        """Check if cache for category is still valid."""
        cache_file = self._cache_dir / f"{category}.json"
        meta_file = self._cache_dir / f"{category}.meta"

        if not cache_file.exists() or not meta_file.exists():
            return False

        try:
            stored_date = meta_file.read_text().strip()
            return stored_date == self._get_todays_cache_date()
        except:
            return False

    def _load_cached_categories(self):
        """Load categories from cache."""
        cache_file = self._cache_dir / "kite.json"
        if cache_file.exists():
            try:
                data = json.loads(cache_file.read_text())
                self._categories = data.get("categories", [])
                self.categoriesChanged.emit()
            except:
                pass

    def _load_cached_articles(self, category):
        """Load articles from cache if valid."""
        if not self._is_cache_valid(category):
            self._fetch_articles_background(category)
            return False

        cache_file = self._cache_dir / f"{category}.json"
        try:
            data = json.loads(cache_file.read_text())
            articles = self._parse_articles(data, category)
            self._articles = articles
            self.articlesChanged.emit()
            return True
        except:
            self._fetch_articles_background(category)
            return False

    def _save_cache(self, category, data):
        """Save data to cache."""
        cache_file = self._cache_dir / f"{category}.json"
        meta_file = self._cache_dir / f"{category}.meta"
        try:
            cache_file.write_text(json.dumps(data))
            meta_file.write_text(self._get_todays_cache_date())
        except:
            pass

    def _check_and_refresh(self):
        """Check if we need to refresh based on 12:00 UTC schedule."""
        if self._active_category and not self._is_cache_valid(self._active_category):
            self._fetch_articles_background(self._active_category)

    def _start_background_fetch_categories(self):
        """Start background thread to fetch categories."""
        thread = threading.Thread(target=self._fetch_categories_thread, daemon=True)
        thread.start()

    def _fetch_categories_thread(self):
        """Fetch categories in background thread."""
        try:
            url = f"{self.BASE_URL}/kite.json"
            with urllib.request.urlopen(url, timeout=10) as response:
                data = json.loads(response.read().decode())

            cache_file = self._cache_dir / "kite.json"
            cache_file.write_text(json.dumps(data))

            self._categoriesFetched.emit(data.get("categories", []))
        except Exception as e:
            self._fetchError.emit(f"Failed to load categories: {e}")

    def _on_categories_fetched(self, categories):
        """Handle categories fetched from background thread."""
        self._categories = categories
        self.categoriesChanged.emit()

        if self._selected_categories and self._active_category:
            if not self._is_cache_valid(self._active_category):
                self._fetch_articles_background(self._active_category)

    def _load_settings(self):
        """Load settings from backend."""
        if self._settings:
            cats = self._settings.getWidgetSetting("news", "selected_categories")
            if cats and isinstance(cats, list):
                self._selected_categories = cats
            elif not cats:
                old_cat = self._settings.getWidgetSetting("news", "selected_category")
                if old_cat:
                    self._selected_categories = [old_cat]

            if self._selected_categories:
                self._active_category = self._selected_categories[0]

    def _save_settings(self):
        """Save settings to backend."""
        if self._settings:
            self._settings.setWidgetSetting(
                "news", "selected_categories", self._selected_categories
            )

    def _build_kagi_link(self, json_category, cluster_number, title, file_timestamp):
        """Build Kagi news link from cluster data."""
        import urllib.parse
        import re

        if (
            not json_category
            or not title
            or cluster_number is None
            or not file_timestamp
        ):
            return ""

        dt = datetime.fromtimestamp(file_timestamp)
        date_part = dt.strftime("%Y%m%d")
        timestamp = f"{date_part}1{cluster_number}"

        slug = title.lower()
        slug = re.sub(r"[^\w\s-]", "", slug)
        slug = re.sub(r"[\s_]+", "-", slug)
        slug = slug.strip("-")
        slug = urllib.parse.quote(slug, safe="-")

        return f"https://news.kagi.com/{json_category}/{timestamp}/{slug}"

    def _parse_articles(self, data, category):
        """Parse articles from API response data."""
        file_timestamp = data.get("timestamp", 0)
        articles = []
        for cluster in data.get("clusters", [])[:10]:
            title = cluster.get("title", "")
            cat = cluster.get("category", "")
            cluster_number = cluster.get("cluster_number", 0)
            cluster_articles = cluster.get("articles", [])
            kagi_link = self._build_kagi_link(
                category, cluster_number, title, file_timestamp
            )

            articles.append(
                {
                    "title": title,
                    "summary": cluster.get("short_summary", "")[:200] + "..."
                    if len(cluster.get("short_summary", "")) > 200
                    else cluster.get("short_summary", ""),
                    "emoji": cluster.get("emoji", ""),
                    "category": cat,
                    "sources": len(cluster_articles),
                    "articles": cluster_articles[:5],
                    "kagiLink": kagi_link,
                }
            )
        return articles

    def _fetch_articles_background(self, category):
        """Start background fetch for articles."""
        if not category:
            return

        self._is_loading = True
        self.isLoadingChanged.emit()
        self._error = ""
        self.errorChanged.emit()

        thread = threading.Thread(
            target=self._fetch_articles_thread, args=(category,), daemon=True
        )
        thread.start()

    def _fetch_articles_thread(self, category):
        """Fetch articles in background thread."""
        try:
            cat_file = f"{category}.json"
            url = f"{self.BASE_URL}/{cat_file}"
            with urllib.request.urlopen(url, timeout=15) as response:
                data = json.loads(response.read().decode())

            self._save_cache(category, data)
            articles = self._parse_articles(data, category)
            file_timestamp = data.get("timestamp", 0)
            self._articlesFetched.emit(category, articles, file_timestamp)

        except Exception as e:
            self._fetchError.emit(f"Failed to load news: {e}")

    def _on_articles_fetched(self, category, articles, timestamp):
        """Handle articles fetched from background thread."""
        if category == self._active_category:
            self._articles = articles
            self.articlesChanged.emit()
        self._is_loading = False
        self.isLoadingChanged.emit()

    def _on_fetch_error(self, error):
        """Handle fetch error from background thread."""
        self._error = error
        self.errorChanged.emit()
        self._is_loading = False
        self.isLoadingChanged.emit()

    def _fetch_articles(self):
        """Fetch articles for active category."""
        if not self._active_category:
            self._articles = []
            self.articlesChanged.emit()
            return

        if not self._load_cached_articles(self._active_category):
            self._fetch_articles_background(self._active_category)

    @Property("QVariantList", notify=categoriesChanged)
    def categories(self):
        return self._categories

    @Property("QVariantList", notify=articlesChanged)
    def articles(self):
        return self._articles

    @Property(bool, notify=isLoadingChanged)
    def isLoading(self):
        return self._is_loading

    @Property(str, notify=errorChanged)
    def error(self):
        return self._error

    @Property("QVariantList", notify=selectedCategoriesChanged)
    def selectedCategories(self):
        return self._selected_categories

    @Property(str, notify=activeCategoryChanged)
    def activeCategory(self):
        return self._active_category

    @Slot(str)
    def toggleCategory(self, category):
        """Toggle a category on/off in the selected list."""
        if category in self._selected_categories:
            self._selected_categories.remove(category)
            if self._active_category == category:
                self._active_category = (
                    self._selected_categories[0] if self._selected_categories else ""
                )
                self.activeCategoryChanged.emit()
                if self._active_category:
                    self._load_cached_articles(self._active_category)
                else:
                    self._articles = []
                    self.articlesChanged.emit()
        else:
            self._selected_categories.append(category)
            self._prefetch_category(category)
            if not self._active_category:
                self._active_category = category
                self.activeCategoryChanged.emit()
                self._load_cached_articles(category)
        self._save_settings()
        self.selectedCategoriesChanged.emit()

    def _prefetch_category(self, category):
        """Prefetch a category in background without updating UI."""
        if self._is_cache_valid(category):
            return
        thread = threading.Thread(
            target=self._fetch_articles_thread, args=(category,), daemon=True
        )
        thread.start()

    @Slot(str)
    def setActiveCategory(self, category):
        """Set the active tab category."""
        if self._active_category != category and category in self._selected_categories:
            self._active_category = category
            self.activeCategoryChanged.emit()
            self._load_cached_articles(category)

    @Slot()
    def refresh(self):
        """Force refresh articles, ignoring cache."""
        if self._active_category:
            self._fetch_articles_background(self._active_category)

    @Slot(str)
    def openArticle(self, url):
        """Open article in browser."""
        import webbrowser

        try:
            webbrowser.open(url)
        except Exception:
            pass
