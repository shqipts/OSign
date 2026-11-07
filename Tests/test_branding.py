from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
class BrandingTests(unittest.TestCase):
    def test_no_github_star_prompt(self):
        source=(ROOT/'Feather/Views/Sources/SourcesView.swift').read_text()
        self.assertNotIn('Feather.shouldStar',source)
        self.assertNotIn('give us a star',source)
    def test_no_old_launch_glyph(self):
        source=(ROOT/'Feather/Resources/Launch Screen.storyboard').read_text()
        self.assertNotIn('Glyph',source)
    def test_supplied_icon_is_selected(self):
        source=(ROOT/'Feather/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json').read_text()
        self.assertIn('osign.png',source)
        self.assertNotIn('feather.png',source)
if __name__=='__main__': unittest.main()
