@echo off

Rem set GRAALVM_HOME=C:\Users\IEUser\Downloads\graalvm\graalvm-ce-19.3.0
Rem set PATH=%PATH%;C:\Users\IEUser\bin

if "%GRAALVM_HOME%"=="" (
    echo Please set GRAALVM_HOME
    exit /b
)

if "%BABASHKA_XMX%"=="" (
    set BABASHKA_XMX="-J-Xmx3g"
)

set JAVA_HOME=%GRAALVM_HOME%
set PATH=%PATH%;%GRAALVM_HOME%\bin

set /P BABASHKA_VERSION=< resources\BABASHKA_VERSION
echo Building Babashka %BABASHKA_VERSION%

call lein with-profiles +reflection do run
if %errorlevel% neq 0 exit /b %errorlevel%

call lein do clean, uberjar
if %errorlevel% neq 0 exit /b %errorlevel%

Rem the --no-server option is not supported in GraalVM Windows.

call %GRAALVM_HOME%\bin\native-image.cmd ^
  "-jar" "target/babashka-%BABASHKA_VERSION%-standalone.jar" ^
  "-H:Name=bb" ^
  "-H:+ReportExceptionStackTraces" ^
  "-J-Dclojure.spec.skip-macros=true" ^
  "-J-Dclojure.compiler.direct-linking=true" ^
  "-H:IncludeResources=BABASHKA_VERSION" ^
  "-H:IncludeResources=SCI_VERSION" ^
  "-H:ReflectionConfigurationFiles=reflection.json" ^
  "--initialize-at-run-time=java.lang.Math$RandomNumberGeneratorHolder" ^
  "--initialize-at-build-time"  ^
  "-H:Log=registerResource:" ^
  "--no-fallback" ^
  "--verbose" ^
  "%BABASHKA_XMX%"

if %errorlevel% neq 0 exit /b %errorlevel%

echo Creating zip archive
jar -cMf babashka-%BABASHKA_VERSION%-windows-amd64.zip bb.exe