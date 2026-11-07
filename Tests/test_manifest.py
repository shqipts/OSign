import importlib.util
from pathlib import Path
import unittest

class ManifestTests(unittest.TestCase):
    def test_manifest_has_exact_metadata_and_https_payload(self):
        spec = importlib.util.spec_from_file_location('manifest', Path(__file__).parents[1] / 'Scripts/make-manifest.py')
        assert spec is not None and spec.loader is not None
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        result = module.make_manifest('https://example.com/App.ipa', 'local.example.app', '1.2', 'A & B')
        self.assertEqual(result['items'][0]['metadata']['title'], 'A & B')
        self.assertEqual(result['items'][0]['assets'][0]['url'], 'https://example.com/App.ipa')
        for value in ['http://example.com/a.ipa', 'https://u:p@example.com/a.ipa', 'file:///a.ipa']:
            with self.assertRaises(ValueError):
                module.make_manifest(value, 'id', '1', 'App')
        with self.assertRaises(ValueError):
            module.make_manifest('https://example.com/a.ipa', '', '1', 'App')

if __name__ == '__main__': unittest.main()
