{ pkgs, androidComposition, androidRootSdk }:

with pkgs;

# Configure your development environment.
#
# Documentation: https://github.com/numtide/devshell
devshell.mkShell {
  name = "android-project";
  motd = ''
    Entered the Android app development environment.
  '';
  env = [
    {
      name = "ANDROID_HOME";
      value = androidRootSdk;
    }
    {
      name = "ANDROID_SDK_ROOT";
      value = androidRootSdk;
    }
    {
      name = "ANDROID_NDK_ROOT";
      value = "${androidRootSdk}/ndk-bundle";
    }
    {
      name = "GRADLE_OPTS";
      value = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidRootSdk}/build-tools/34.0.0/aapt2";
    }
    {
      name = "JAVA_HOME";
      value = zulu17.home;
    }
  ];
  packages = [
    ruby_3_1
    zulu17 
    (callPackage gradle-packages.gradle_8 {
      java = zulu17;
    })
    git 
    androidComposition.androidsdk
    nodejs_18 
    nodePackages.yarn
    watchman
  ];
}
