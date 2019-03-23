{-# LANGUAGE OverloadedStrings #-}

module Main where

import Data.Function ((&))

import qualified Data.ByteString.Lazy.Char8 as ByteString
import qualified Data.Maybe as Maybe
import qualified Data.String as String
import qualified Network.HTTP.Types as HTTP
import qualified Network.Wai as Wai
import qualified Network.Wai.Handler.Warp as Warp
import qualified System.Environment as Environment
import qualified Text.Printf as Printf

main :: IO ()
main = do
  settings <- getSettings
  logStartup settings
  Warp.runSettings settings application

getSettings :: IO Warp.Settings
getSettings = do
  host <- getHost
  port <- getPort
  pure (Warp.defaultSettings
    & Warp.setHost host
    & Warp.setPort port)

getHost :: IO Warp.HostPreference
getHost = do
  maybeHost <- Environment.lookupEnv "HOST"
  let host = Maybe.fromMaybe "127.0.0.1" maybeHost
  pure (String.fromString host)

getPort :: IO Warp.Port
getPort = do
  maybePort <- Environment.lookupEnv "PORT"
  let port = Maybe.fromMaybe "8080" maybePort
  pure (read port)

logStartup :: Warp.Settings -> IO ()
logStartup settings = do
  let host = Warp.getHost settings
  let port = Warp.getPort settings
  Printf.printf "Listening on %s port %d ...\n" (show host) port

application :: Wai.Application
application _request respond =
  let
    status = HTTP.status200
    headers =
      [
        (HTTP.hContentType, "application/json")
      ]
    body = ByteString.pack "{\"message\":\"Hello, world!\"}"
  in respond (Wai.responseLBS status headers body)
