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
    selectedCategoryChanged = Signal()

    BASE_URL = "https://kite.kagi.com"

    def __init__(self, settings_backend=None, parent=None):
        super().__init__(parent)
        self._settings = settings_backend

        # State
        self._categories = []
        self._articles = []
        self._is_loading = False
        self._error = ""
        self._selected_category = "tech"  # Default

        # Load settings
        self._load_settings()

        # Auto-refresh timer (15 minutes)
        self._refresh_timer = QTimer(self)
        self._refresh_timer.timeout.connect(self.refresh)
        self._refresh_timer.start(15 * 60 * 1000)

        # Load categories on init
        self._fetch_categories()

    def _load_settings(self):
        """Load settings from backend."""
        if self._settings:
            cat = self._settings.getWidgetSetting("news", "selected_category")
            if cat:
                self._selected_category = cat

    def _save_settings(self):
        """Save settings to backend."""
        if self._settings:
            self._settings.setWidgetSetting(
                "news", "selected_category", self._selected_category
            )

    def _fetch_categories(self):
        """Fetch available categories."""
        try:
            url = f"{self.BASE_URL}/kite.json"
            with urllib.request.urlopen(url, timeout=10) as response:
                data = json.loads(response.read().decode())

            self._categories = data.get("categories", [])
            self.categoriesChanged.emit()

            # Fetch articles for selected category
            self._fetch_articles()

        except Exception as e:
            self._error = f"Failed to load categories: {e}"
            self.errorChanged.emit()

    def _build_kagi_link(self, json_category, cluster_number, title, articles):
        """Build Kagi news link from cluster data."""
        import urllib.parse
        import re
        from datetime import datetime

        if not json_category or not title or cluster_number is None:
            return ""

        date_part = ""
        if articles:
            date_str = articles[0].get("date", "")
            if date_str:
                try:
                    dt = datetime.fromisoformat(
                        date_str.replace("+00:00", "").replace("Z", "")
                    )
                    date_part = dt.strftime("%Y%m%d")
                except (ValueError, AttributeError):
                    pass

        if not date_part:
            return ""

        timestamp = f"{date_part}1{cluster_number}"

        slug = title.lower()
        slug = re.sub(r"[^\w\s-]", "", slug)
        slug = re.sub(r"[\s_]+", "-", slug)
        slug = slug.strip("-")
        slug = urllib.parse.quote(slug, safe="-")

        return f"https://news.kagi.com/{json_category}/{timestamp}/{slug}"

    def _fetch_articles(self):
        """Fetch articles for selected category."""
        if not self._selected_category:
            return

        self._is_loading = True
        self.isLoadingChanged.emit()
        self._error = ""
        self.errorChanged.emit()

        try:
            # Find the file for selected category
            cat_file = None
            for cat in self._categories:
                if cat.get("file", "").replace(".json", "") == self._selected_category:
                    cat_file = cat.get("file")
                    break

            if not cat_file:
                # Try direct file name
                cat_file = f"{self._selected_category}.json"

            url = f"{self.BASE_URL}/{cat_file}"
            with urllib.request.urlopen(url, timeout=15) as response:
                data = json.loads(response.read().decode())

            articles = []
            for cluster in data.get("clusters", [])[:10]:
                title = cluster.get("title", "")
                category = cluster.get("category", "")
                cluster_number = cluster.get("cluster_number", 0)
                cluster_articles = cluster.get("articles", [])
                kagi_link = self._build_kagi_link(
                    self._selected_category, cluster_number, title, cluster_articles
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

    # Properties
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

    @Property(str, notify=selectedCategoryChanged)
    def selectedCategory(self):
        return self._selected_category

    # Slots
    @Slot(str)
    def setCategory(self, category):
        """Set selected category and refresh."""
        if self._selected_category != category:
            self._selected_category = category
            self._save_settings()
            self.selectedCategoryChanged.emit()
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
