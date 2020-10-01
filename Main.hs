{-# LANGUAGE GADTs, TypeApplications #-}

import Data.Text (Text)
import qualified Data.Text as Text
import Control.Monad.Trans.Reader (runReaderT)

import qualified Diagrams.Prelude as D
import qualified Diagrams.Backend.Cairo as D
import qualified Diagrams.Backend.Cairo.Internal as D (Options(CairoOptions))

import qualified GI.Gtk as Gtk
import qualified GI.Gio as Gio

import qualified GI.Cairo as GI.Cairo
import qualified Graphics.Rendering.Cairo as Cairo
import qualified Graphics.Rendering.Cairo.Internal as Cairo (Render(runRender))
import Graphics.Rendering.Cairo.Types (Cairo(Cairo))
import Foreign.Ptr (castPtr)

main :: IO ()
main = do
  Just app <- Gtk.applicationNew (Just appId) []
  _ <- Gio.onApplicationActivate app (appActivate app)
  _ <- Gio.applicationRun app Nothing
  return ()

appId :: Text
appId = Text.pack "int-index.gtk-diagrams"

diagram :: D.Diagram D.B
diagram =
    D.strokeT (hilbert (6 :: Integer))
      D.# D.lc D.silver
      D.# D.opacity 0.3
  where
    hilbert 0 = mempty
    hilbert n =
             hilbert' (n-1) D.# D.reflectY D.<> D.vrule 1
        D.<> hilbert  (n-1) D.<> D.hrule 1
        D.<> hilbert  (n-1) D.<> D.vrule (-1)
        D.<> hilbert' (n-1) D.# D.reflectX
      where
        hilbert' m = hilbert m D.# D.rotateBy (1/4)

appActivate :: Gtk.Application -> IO ()
appActivate app = do
  window <- Gtk.applicationWindowNew app
  Gtk.setWindowTitle window (Text.pack "GTK+ Diagrams")
  Gtk.setWindowResizable window False
  Gtk.setWindowDefaultHeight window 300
  Gtk.setWindowDefaultWidth window 300
  Gtk.setWidgetAppPaintable window True

  _ <- Gtk.onWidgetDraw window $ \context -> do
    renderWithContext context $ do
      (x1, y1, x2, y2) <- Cairo.clipExtents
      let (w, h) = (x2 - x1, y2 - y1)
      Cairo.rectangle 0 0 w h
      Cairo.setSourceRGB 0.1 0.1 0.5
      Cairo.fill
      Cairo.setSourceRGB 1 1 1
      snd (D.renderDia D.Cairo (D.CairoOptions "" (D.mkWidth w) D.RenderOnly False) diagram)
    return True

  Gtk.widgetShow window

renderWithContext :: GI.Cairo.Context -> Cairo.Render () -> IO ()
renderWithContext ct r =
  Gtk.withManagedPtr ct $ \p ->
  runReaderT (Cairo.runRender r) (Cairo (castPtr p))
