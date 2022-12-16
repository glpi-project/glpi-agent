#! /bin/bash

# Patch appimage-builder installed via pip has it fails to parse few packages version
# See https://github.com/AppImageCrafters/appimage-builder/issues/280

set -e

LOCATION="$( pip show appimage-builder | grep Location: | sed -re 's/^Location: //' )"

cd "$LOCATION/appimagebuilder/modules/deploy/apt"

patch -p1 <<PACKAGE_PY_PATCH
diff --git a/package.py b/package.py
--- a/package.py
+++ b/package.py
@@ -76,7 +76,7 @@ class Package:
 
     def __gt__(self, other):
         if isinstance(other, Package):
-            return version.parse(self.version) > version.parse(other.version)
+            return version.parse(self.version.replace("ubuntu", "+ubuntu")) > version.parse(other.version.replace("ubuntu", "+ubuntu"))
 
     def __hash__(self):
         return self.__str__().__hash__()
PACKAGE_PY_PATCH
