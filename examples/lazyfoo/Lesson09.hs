{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}
module Lazyfoo.Lesson09 where

import Control.Applicative
import Control.Monad
import Data.Foldable (for_)
import Foreign.C.Types
import Linear
import Linear.Affine
import qualified SDL

screenWidth, screenHeight :: CInt
(screenWidth, screenHeight) = (640, 480)

loadSurface :: FilePath -> SDL.Surface -> IO SDL.Surface
loadSurface path screenSurface = do
  loadedSurface <- SDL.loadBMP path
  desiredFormat <- SDL.surfaceFormat screenSurface
  SDL.convertSurface loadedSurface desiredFormat <* SDL.freeSurface loadedSurface

main :: IO ()
main = do
  SDL.init [SDL.InitVideo]

  hintSet <- SDL.setHint SDL.HintRenderScaleQuality SDL.ScaleLinear
  unless hintSet $
    putStrLn "Warning: Linear texture filtering not enabled!"

  window <-
    SDL.createWindow
      "SDL Tutorial"
      SDL.defaultWindow {SDL.windowSize = V2 screenWidth screenHeight}
  SDL.showWindow window

  renderer <-
    SDL.createRenderer
      window
      (-1)
      (SDL.RendererConfig
         { SDL.rendererAccelerated = True
         , SDL.rendererSoftware = False
         , SDL.rendererTargetTexture = False
         , SDL.rendererPresentVSync = False
         })

  SDL.setRenderDrawColor renderer (V4 maxBound maxBound maxBound maxBound)

  textureSurface <- SDL.loadBMP "examples/lazyfoo/viewport.bmp"
  texture <- SDL.createTextureFromSurface renderer textureSurface
  SDL.freeSurface textureSurface

  let loop = do
        let collectEvents = do
              e <- SDL.pollEvent
              case e of
                Nothing -> return []
                Just e' -> (e' :) <$> collectEvents
        events <- collectEvents

        let quit =
              any (\case SDL.QuitEvent -> True
                         _ -> False) $
              map SDL.eventPayload events

        SDL.setRenderDrawColor renderer (V4 maxBound maxBound maxBound maxBound)
        SDL.renderClear renderer

        SDL.renderSetViewport renderer (Just $ SDL.Rectangle (P (V2 0 0)) (V2 (screenWidth `div` 2) (screenHeight `div` 2)))
        SDL.renderCopy renderer texture Nothing Nothing

        SDL.renderSetViewport renderer (Just $ SDL.Rectangle (P (V2 (screenWidth `div` 2) 0)) (V2 (screenWidth `div` 2) (screenHeight `div` 2)))
        SDL.renderCopy renderer texture Nothing Nothing

        SDL.renderSetViewport renderer (Just $ SDL.Rectangle (P (V2 0 (screenHeight `div` 2))) (V2 screenWidth (screenHeight `div` 2)))
        SDL.renderCopy renderer texture Nothing Nothing

        SDL.renderPresent renderer

        unless quit loop

  loop

  SDL.destroyRenderer renderer
  SDL.destroyWindow window
  SDL.quit