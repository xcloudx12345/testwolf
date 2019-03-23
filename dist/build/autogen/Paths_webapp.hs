module Paths_webapp (
    version,
    getBinDir, getLibDir, getDataDir, getLibexecDir,
    getDataFileName, getSysconfDir
  ) where

import qualified Control.Exception as Exception
import Data.Version (Version(..))
import System.Environment (getEnv)
import Prelude

catchIO :: IO a -> (Exception.IOException -> IO a) -> IO a
catchIO = Exception.catch

version :: Version
version = Version [0,1,0,0] []
bindir, libdir, datadir, libexecdir, sysconfdir :: FilePath

bindir     = "/app/.cabal/bin"
libdir     = "/app/.cabal/lib/x86_64-linux-ghc-7.10.3/webapp-0.1.0.0-E2okZwtmP7N6UwlPNbMSwo"
datadir    = "/app/.cabal/share/x86_64-linux-ghc-7.10.3/webapp-0.1.0.0"
libexecdir = "/app/.cabal/libexec"
sysconfdir = "/app/.cabal/etc"

getBinDir, getLibDir, getDataDir, getLibexecDir, getSysconfDir :: IO FilePath
getBinDir = catchIO (getEnv "webapp_bindir") (\_ -> return bindir)
getLibDir = catchIO (getEnv "webapp_libdir") (\_ -> return libdir)
getDataDir = catchIO (getEnv "webapp_datadir") (\_ -> return datadir)
getLibexecDir = catchIO (getEnv "webapp_libexecdir") (\_ -> return libexecdir)
getSysconfDir = catchIO (getEnv "webapp_sysconfdir") (\_ -> return sysconfdir)

getDataFileName :: FilePath -> IO FilePath
getDataFileName name = do
  dir <- getDataDir
  return (dir ++ "/" ++ name)
