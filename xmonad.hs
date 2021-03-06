{-# OPTIONS_GHC -Wall -Wno-missing-signatures -Wno-name-shadowing #-}
-- My xmonad.hs
-- Import  --{{{1

import XMonad
import XMonad.Actions.CycleWS
import XMonad.Actions.FloatSnap
import XMonad.Actions.NoBorders
import XMonad.Actions.Promote
import XMonad.Actions.Submap
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.EwmhDesktops
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.ManageHelpers
import XMonad.Hooks.SetWMName
import XMonad.Hooks.UrgencyHook
import XMonad.Layout.Gaps
import XMonad.Layout.MultiPanes
import XMonad.Layout.Named
import XMonad.Layout.NoBorders
import XMonad.Layout.Spacing
import XMonad.Layout.ToggleLayouts
import XMonad.Prompt
import XMonad.Prompt.Shell
import XMonad.Util.Cursor
import XMonad.Util.Run
import XMonad.Util.WorkspaceCompare
import qualified XMonad.StackSet as W

import Control.Monad (filterM)
import Data.List (find, isPrefixOf)
import Data.Monoid (All(..))
import System.Exit (exitWith, ExitCode(..))
import qualified Data.Map as M




-- Configs  --{{{1

myTerminal = "alacritty"
myBorderWidth = 2
myModMask = mod4Mask
myWorkspaces = map show [(1 :: Int)..9]
myStatusbarHeight = 21

myFont = "xft:M PLUS Code Latin 60:pixelsize=11,Noto Sans CJK JP:pixelsize=11,Noto Emoji:pixelsize=11"

myGrayColor1 = "#f5f6f7"
myGrayColor2 = "#e8eaeb"
myGrayColor3 = "#d9dadb"
myGrayColor4 = "#c5c6c7"
myGrayColor5 = "#a8aeb3"
myGrayColor6 = "#869096"
myGrayColor7 = "#657078"
myGrayColor8 = "#4e5a61"
myGrayColor9 = "#363f45"
myGrayColor10 = "#21272b"

myAccentColor1 = "#e6f5ff"
myAccentColor2 = "#d4eeff"
myAccentColor3 = "#b6e0fc"
myAccentColor4 = "#8dd0fc"
myAccentColor5 = "#5ebaf7"
myAccentColor6 = "#1c95e6"
myAccentColor7 = "#0675bf"
myAccentColor8 = "#015994"
myAccentColor9 = "#024069"
myAccentColor10 = "#022338"

myXPConfig ref = (def :: XPConfig)
  { font              = myFont
  , fgColor           = myGrayColor1
  , bgColor           = myGrayColor10
  , fgHLight          = myAccentColor5
  , bgHLight          = myGrayColor10
  , borderColor       = myGrayColor10
  , promptBorderWidth = 0
  , position          = Top
  , height            = myStatusbarHeight
  , historyFilter     = deleteAllDuplicates
  , promptKeymap      = M.union myKeymap emacsLikeXPKeymap
  }
  where
    myKeymap = M.fromList $
      [ ((controlMask, xK_u), setInput "")
      , ((controlMask, xK_h), deleteString Prev)
      , ((controlMask, xK_m), setSuccess True >> setDone True)
      , ((controlMask, xK_n), historyDownMatching ref)
      , ((controlMask, xK_p), historyUpMatching ref)
      , ((controlMask, xK_w), killWord Prev)
      ]




-- Hooks  --{{{1
-- EventHook  --{{{2

myEventHook = removeBorderEventHook (className =? "Wine")

removeBorderEventHook :: Query Bool -> XMonad.Event -> X All
removeBorderEventHook query e = do
  whenX (query `runQuery` w) $ do
    d <- asks display
    io $ setWindowBorderWidth d w 0
  return $ All True
  where
    w = ev_window e





-- LayoutHook  --{{{2

myLayoutHook = avoidStruts $ smartBorders $ toggleLayouts Full $
               spacing 4 $ gaps [(U, 4), (D, 4), (L, 4), (R, 4)] $
               (tallLayout ||| threeColLayout)
  where
    tallLayout = named "Tall" $ MultiPanes (3/100) ((3/100) * (16/9))
      [ Pane (PaneSlotAtMost 1) (1/2) []
      , Pane (PaneSlotAtLeast 1) (1/2) []
      ]
    threeColLayout = named "ThreeCol" $ MultiPanes (3/100) ((3/100) * (16/9))
      [ Pane (PaneSlotAtMost 1) (2/4) []
      , Pane (PaneSlotAtLeast 1) (1/4) []
      , Pane (PaneSlotAtLeast 2) (1/4) []
      ]




-- LogHook  --{{{2

myLogHook h = do
  floated <- withWindowSet isFloat
  dynamicLogWithPP $ def
    { ppOutput           = hPutStrLn h
    , ppCurrent          = xmobarColorWithOffset myGrayColor10 myAccentColor5 . wrapSpaces
    , ppHidden           = wrapSpaces
    , ppHiddenNoWindows  = xmobarColor myGrayColor6 "" . wrapSpaces
    , ppUrgent           = wrap "*" " "
    , ppSep              = xmobarColor myGrayColor8 "" $ wrap " " " " $ xmobarIcon "separator.xbm"
    , ppWsSep            = ""
    , ppTitle            = if floated then ("<fn=1>\xe069</fn> " ++) else id
    , ppTitleSanitize    = xmobarRaw
    , ppLayout           = xmobarColor myAccentColor5 "" . layoutIcon
    }
  where
    layoutIcon name = case name of
      "Spacing Tall"     -> xmobarIcon "layout-tall.xbm"
      "Spacing ThreeCol" -> xmobarIcon "layout-threecol.xbm"
      "Full"             -> xmobarIcon "layout-full.xbm"
      _                  -> xmobarRaw name
    xmobarIcon = wrap "<icon=" "/>"
    xmobarColorWithOffset fg bg = wrap ("<fc=" ++ fg ++ "," ++ bg ++ ":1>") "</fc>"
    wrapSpaces = wrap " " " "
    isFloat ws = return $ case W.peek ws of
      Nothing -> False
      Just w  -> M.member w $ W.floating ws




-- ManageHook  --{{{2

myManageHook = manageDocks
  <+> composeOne
    [ className =? "Firefox" <&&> appName /=? "Navigator" -?> doFloat
    , className =? "Geeqie"                               -?> doShiftEmptyAndGo
    , className =? "Gimp"                                 -?> doShiftEmptyAndGo
    , className =? "Inkscape"                             -?> doShiftEmptyAndGo
    , className =? "Pavucontrol"                          -?> doCenterFloat
    , className =? "XFontSel"                             -?> doCenterFloat
    , className =? "Xmessage"                             -?> doCenterFloat
    , className =? "feh"                                  -?> doCenterFloat
    , className =? "fontforge"                            -?> doShiftEmptyAndGo <+> doFloat
    , className =? "libreoffice-startcenter"              -?> doShiftEmptyAndGo
    , className =? "mpv"                                  -?> doCenterFloat
    , title     =? "Wine System Tray"                     -?> doHideIgnore
    ]
  <+> composeOne
    [ isFullscreen     -?> doFullFloat
    , isDialog         -?> doCenterFloat
    , role =? "pop-up" -?> doFloat
    , isUnknown        -?> doFloat
    ]
  where
    doShiftAndGo ws = doF (W.greedyView ws) <+> doShift ws
    doShiftEmptyAndGo = do
      w <- ask
      c <- liftX $ runQuery className w
      ws <- liftX $ withWindowSet $ filterM (runQuery $ className =? c) . W.index
      case ws of
        [] -> do
          workspace <- liftX (W.workspace . W.current <$> gets windowset)
          case W.stack workspace of
            Nothing -> doShiftAndGo $ W.tag workspace
            _       -> doShiftAndGo =<< liftX (findWorkspace getSortByIndex Next emptyWS 1)
        _ -> idHook
    isUnknown = (not <$> hasProperty "WM_CLASS") <&&> (not <$> hasProperty "WM_WINDOW_ROLE")
    hasProperty p = ask >>= \w -> liftX $ withDisplay $ \d ->
      maybe False (const True) <$> getStringProperty d w p
    role = stringProperty "WM_WINDOW_ROLE"




-- StartupHook  --{{{2

myStartupHook = do
  setWMName "LG3D"
  setDefaultCursor xC_left_ptr
  return ()




-- Keys  --{{{1

myKeys conf@(XConfig { XMonad.modMask = modMask }) = M.fromList $
  [ ((modMask,                 xK_Return),       promote)
  , ((modMask .|. shiftMask,   xK_Return),       safeSpawnProg $ terminal conf)

  , ((modMask,                 xK_space),        sendMessage NextLayout)
  , ((modMask .|. shiftMask,   xK_space),        setLayout $ layoutHook conf)

  , ((modMask,                 xK_Tab),          moveTo Next (Not emptyWS))
  , ((modMask .|. shiftMask,   xK_Tab),          moveTo Prev (Not emptyWS))

  , ((modMask,                 xK_j),            windows W.focusDown)
  , ((modMask,                 xK_k),            windows W.focusUp)
  , ((modMask .|. shiftMask,   xK_j),            windows W.swapDown)
  , ((modMask .|. shiftMask,   xK_k),            windows W.swapUp)

  , ((modMask,                 xK_h),            sendMessage Shrink)
  , ((modMask,                 xK_l),            sendMessage Expand)
  , ((modMask .|. shiftMask,   xK_h),            sendMessage ShrinkClient)
  , ((modMask .|. shiftMask,   xK_l),            sendMessage ExpandClient)

  , ((modMask,                 xK_b),            sendMessage ToggleStruts)
  , ((modMask,                 xK_f),            sendMessage ToggleLayout)
  , ((modMask,                 xK_g),            withFocused toggleBorder)
  , ((modMask,                 xK_m),            windows W.focusMaster)
  , ((modMask,                 xK_t),            withFocused $ windows . W.sink)

  , ((modMask,                 xK_comma),        sendMessage $ IncMasterN (-1))
  , ((modMask,                 xK_period),       sendMessage $ IncMasterN (1))

  , ((modMask .|. shiftMask,   xK_c),            kill)
  , ((modMask .|. shiftMask,   xK_q),            io $ exitWith ExitSuccess)
  , ((modMask,                 xK_r),            refresh)
  , ((modMask .|. shiftMask,   xK_r),            spawn "xmonad --recompile && xmonad --restart")

  , ((modMask,                 xK_p),            initMatches >>= shellPrompt . myXPConfig)

  , ((modMask,                 xK_equal),        safeSpawn "amixer" ["-q", "set", "Master", "5%+"])
  , ((modMask,                 xK_minus),        safeSpawn "amixer" ["-q", "set", "Master", "5%-"])
  , ((modMask,                 xK_0),            safeSpawn "amixer" ["-q", "set", "Master", "toggle"])

  , ((modMask .|. shiftMask,   xK_equal),        safeSpawn "mpc" ["volume", "+5"])
  , ((modMask .|. shiftMask,   xK_minus),        safeSpawn "mpc" ["volume", "-5"])

  , ((modMask,                 xK_backslash),    safeSpawn "mpc" ["toggle"])
  , ((modMask,                 xK_bracketleft),  safeSpawn "mpc" ["prev"])
  , ((modMask,                 xK_bracketright), safeSpawn "mpc" ["next"])

  , ((modMask .|. shiftMask,   xK_bracketleft),  switchPrimaryCardProfile "output:analog-stereo")
  , ((modMask .|. shiftMask,   xK_bracketright), switchPrimaryCardProfile "output:hdmi-stereo")

  , ((modMask,                 xK_Print),        safeSpawn "scrot" ["-e", "mv $f \\$HOME/Desktop/"])

  , ((modMask .|. controlMask, xK_l),            spawn "sleep 1; xset dpms force off")

  , ((modMask .|. mod1Mask,    xK_j),            withFocused $ snapMove D Nothing)
  , ((modMask .|. mod1Mask,    xK_k),            withFocused $ snapMove U Nothing)
  , ((modMask .|. mod1Mask,    xK_h),            withFocused $ snapMove L Nothing)
  , ((modMask .|. mod1Mask,    xK_l),            withFocused $ snapMove R Nothing)

  , ((modMask,                 xK_x),            submap $ M.fromList $
                                                        [ ((mask .|. mask', key), action)
                                                        | ((mask, key), action) <- lancherKeys
                                                        , mask' <- [0, modMask]
                                                        ])
  ] ++ workspaceKeys
  where
    workspaceKeys = [ ((m, k), windows $ f w)
                    | (m, f) <- [(modMask, W.greedyView), (modMask .|. shiftMask, W.shift)]
                    , (k, w) <- zip [xK_1 .. xK_9] (XMonad.workspaces conf)
                    ]

    lancherKeys = [ ((0,         xK_2), safeSpawn "v2c" [])
                  , ((0,         xK_c), safeSpawn "brave-bin" [])
                  , ((shiftMask, xK_c), safeSpawn "brave-bin" ["--profile-directory=Profile 1"])
                  , ((0,         xK_f), safeSpawn "firefox-bin" [])
                  , ((0,         xK_g), safeSpawn "geeqie" [])
                  , ((0,         xK_p), safeSpawn "pavucontrol" [])
                  , ((0,         xK_t), safeSpawn "transmission-gtk" [])
                  ]

listPulseAudioCards :: (MonadIO m) => m [String]
listPulseAudioCards = do
  output <- runProcessWithInput "pactl" ["list", "cards", "short"] ""
  return $ map (fst . break isTab . dropWhile isTab . snd . break isTab)
         $ lines output
  where
    isTab = (==) '\t'

switchPrimaryCardProfile :: (MonadIO m) => String -> m ()
switchPrimaryCardProfile profile = do
  cards <- listPulseAudioCards
  case find (isPrefixOf "alsa_card.pci-") cards of
    (Just card) -> safeSpawn "pactl" ["set-card-profile", card, profile]
    _           -> return ()




-- Mouse Bindings --{{{1

myMouseBindings (XConfig { XMonad.modMask = modMask }) = M.fromList
  [ ((modMask, button1), \w -> focus w >> mouseMoveWindow w
                                       >> windows W.shiftMaster)
  , ((modMask, button2), windows . (W.shiftMaster .) . W.focusWindow)
  , ((modMask, button3), \w -> focus w >> mouseResizeWindow w >> windows W.shiftMaster)
  , ((modMask, 8),       \w -> focus w >> findWorkspace getSortByIndex Prev anyWS 1
                                       >>= windows . W.shift)
  , ((modMask, 9),       \w -> focus w >> findWorkspace getSortByIndex Next anyWS 1
                                       >>= windows . W.shift)
  ]




-- Main  --{{{1

main = do
  statusPipe <- spawnPipe "xmobar"

  xmonad $ withUrgencyHook NoUrgencyHook $ docks $ ewmhFullscreen $ ewmh $ def
    { terminal           = myTerminal
    , borderWidth        = myBorderWidth
    , modMask            = myModMask
    , workspaces         = myWorkspaces

    , normalBorderColor  = myGrayColor10
    , focusedBorderColor = myAccentColor6

    , keys               = myKeys
    , mouseBindings      = myMouseBindings

    , handleEventHook    = myEventHook
    , layoutHook         = myLayoutHook
    , logHook            = myLogHook statusPipe
    , manageHook         = myManageHook
    , startupHook        = myStartupHook

    , focusFollowsMouse  = True
    }




-- __END__  --{{{1
-- vim: expandtab softtabstop=2 shiftwidth=2
-- vim: foldmethod=marker
