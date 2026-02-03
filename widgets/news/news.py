import json
import urllib.request
import urllib.error
from PySide6.QtCore import QObject, Property, Signal, Slot, QTimer


class NewsBackend(QObject):
    """Backend for Kagi News widget."""

    categoriesChanged = Signal()
    articlesChanged = Signal()
    isLoadingChanged = Signal()
    errorChanged = Signal()
    selectedCategoriesChanged = Signal()
    activeCategoryChanged = Signal()

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

        self._load_settings()

        self._refresh_timer = QTimer(self)
        self._refresh_timer.timeout.connect(self.refresh)
        self._refresh_timer.start(15 * 60 * 1000)

        self._fetch_categories()

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

    def _fetch_categories(self):
        """Fetch available categories."""
        try:
            url = f"{self.BASE_URL}/kite.json"
            with urllib.request.urlopen(url, timeout=10) as response:
                data = json.loads(response.read().decode())

            self._categories = data.get("categories", [])
            self.categoriesChanged.emit()

            if self._selected_categories and self._active_category:
                self._fetch_articles()

        except Exception as e:
            self._error = f"Failed to load categories: {e}"
            self.errorChanged.emit()

    def _build_kagi_link(self, json_category, cluster_number, title, file_timestamp):
        """Build Kagi news link from cluster data."""
        import urllib.parse
        import re
        from datetime import datetime

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

    def _fetch_articles(self):
        """Fetch articles for active category."""
        if not self._active_category:
            self._articles = []
            self.articlesChanged.emit()
            return

        self._is_loading = True
        self.isLoadingChanged.emit()
        self._error = ""
        self.errorChanged.emit()

        try:
            cat_file = None
            for cat in self._categories:
                if cat.get("file", "").replace(".json", "") == self._active_category:
                    cat_file = cat.get("file")
                    break

            if not cat_file:
                cat_file = f"{self._active_category}.json"

            url = f"{self.BASE_URL}/{cat_file}"
            with urllib.request.urlopen(url, timeout=15) as response:
                data = json.loads(response.read().decode())

            file_timestamp = data.get("timestamp", 0)
            articles = []
            for cluster in data.get("clusters", [])[:10]:
                title = cluster.get("title", "")
                category = cluster.get("category", "")
                cluster_number = cluster.get("cluster_number", 0)
                cluster_articles = cluster.get("articles", [])
                kagi_link = self._build_kagi_link(
                    self._active_category, cluster_number, title, file_timestamp
                )

                articles.append(
                    {
                        "title": title,
                        "summary": cluster.get("short_summary", "")[:200] + "..."
                        if len(cluster.get("short_summary", "")) > 200
                        else cluster.get("short_summary", ""),
                        "emoji": cluster.get("emoji", ""),
                        "category": category,
                        "sources": len(cluster_articles),
                        "articles": cluster_articles[:5],
                        "kagiLink": kagi_link,
                    }
                )

            self._articles = articles
            self.articlesChanged.emit()

        except urllib.error.URLError as e:
            self._error = f"Network error: {e}"
            self.errorChanged.emit()
        except json.JSONDecodeError as e:
            self._error = f"Failed to parse news: {e}"
            self.errorChanged.emit()
        except Exception as e:
            self._error = f"Failed to load news: {e}"
            self.errorChanged.emit()
        finally:
            self._is_loading = False
            self.isLoadingChanged.emit()

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
                self._fetch_articles()
        else:
            self._selected_categories.append(category)
            if not self._active_category:
                self._active_category = category
                self.activeCategoryChanged.emit()
                self._fetch_articles()
        self._save_settings()
        self.selectedCategoriesChanged.emit()

    @Slot(str)
    def setActiveCategory(self, category):
        """Set the active tab category."""
        if self._active_category != category and category in self._selected_categories:
            self._active_category = category
            self.activeCategoryChanged.emit()
            self._fetch_articles()

    @Slot()
    def refresh(self):
        """Refresh articles."""
        self._fetch_articles()

    @Slot(str)
    def openArticle(self, url):
        """Open article in browser."""
        import webbrowser

        try:
            webbrowser.open(url)
        except Exception:
            pass
