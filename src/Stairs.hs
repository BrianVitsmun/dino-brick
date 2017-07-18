-- {-# LANGUAGE TemplateHaskell, FlexibleContexts #-}
{-# LANGUAGE TemplateHaskell #-}

module Stairs where

import Control.Applicative (liftA2)
import Lens.Micro.TH (makeLenses)
import Lens.Micro ((&), (.~), (%~), (^.))
import Linear.V2 (V2(..), _x, _y, _xy)
import System.Random (Random(..), newStdGen)
import qualified Data.Sequence as S
import Data.Ix (inRange)

-- Types
data Game = Game
  { _lFoot   :: Foot         -- ^ foot with position and size
  , _lDir    :: Direction    -- ^ direction of left foot
  , _rFoot   :: Foot         -- ^ foot with position and size
  , _rDir    :: Direction    -- ^ direction of right foot
  , _sStairs :: S.Seq Stair  -- ^ sequence of stairs on screen
  , _nStairs :: Stream Stair -- ^ infinite list of random next stair locations
  , _dead    :: Bool         -- ^ game over flag
  , _score   :: Int          -- ^ score
  } deriving (Show)

type Coord = V2 Int
type Size = Int
data Stair = Stair { _sPos :: Coord, _sWidth :: Size, _sHeight :: Size}
  deriving (Show, Eq)
data Foot = Foot { _fPos :: Coord, _fSize :: Size }
  deriving (Show, Eq)

data Stream a = a :| Stream a
  deriving (Show)

data Direction =
    Up
  | Down
  | Still
  deriving (Eq, Show)

makeLenses ''Game
makeLenses ''Stair
makeLenses ''Foot

-- Constants
gridWidth, gridHeight :: Int
gridWidth = 30
gridHeight = 30

footSize, stairHeight :: Size
footSize = 2
stairHeight = 3 -- We will vary star width, but not stair height

-- | Used for centering calculations
betweenSpace, lX, rX :: Int
betweenSpace = 8 -- Choose even number to make math nice
lX = (gridWidth - betweenSpace) `div` 2 - footSize
rX = lX + betweenSpace + footSize

-- | Choose coordinates such that feet are centered
lFootStart, rFootStart :: Foot
lFootStart = Foot (V2 lX 0) footSize
rFootStart = Foot (V2 rX 0) footSize

stairLow, stairHigh :: Stair
stairLow = Stair (V2 0 0) 10 stairHeight
stairHigh = Stair (V2 10 10) 20 stairHeight

-- Functions
-- | Step forward in time
step :: Game -> Game
step g = g -- TODO: fix this

-- | Initialize a game with random stair location
initGame :: IO Game
initGame = do
  randStairs <- randomStairs
  let g = Game { _lFoot = lFootStart
               , _rFoot = rFootStart
               , _sStairs = S.empty
               , _nStairs = randStairs
               , _dead = False
               , _score = 0 }
  return g

randomStairs :: IO (Stream Stair)
randomStairs = fromList . randomRs (stairLow, stairHigh) <$> newStdGen

fromList :: [a] -> Stream a
fromList = foldr (:|) (error "Streams must be infinite")

-- | Determines whether passed-in coordinate is part of the feet.
isFeet :: Coord -> Game -> Bool
isFeet c g = isFoot c (g^.lFoot) || isFoot c (g^.rFoot)

isFoot :: Coord -> Foot -> Bool
isFoot (V2 a b) foot =
  let (V2 x y) = foot^.fPos._xy
      xBounds = (x, x + foot^.fSize)
      yBounds = (y, y + foot^.fSize)
  in inRange xBounds a && inRange yBounds b

-- Instances
instance Random Stair where
  randomR (s1, s2) g =
    let (pos, g')    = randomR (s1^.sPos, s2^.sPos) g
        (width, g'') = randomR (s1^.sWidth, s2^.sWidth) g'
    in (Stair pos width stairHeight, g'')
  random g =
    let (pos, g')    = random g
        (width, g'') = random g'
    in (Stair pos width stairHeight, g'')

instance Random a => Random (V2 a) where
  randomR (V2 x1 y1, V2 x2 y2) g =
    let (x, g')  = randomR (x1, x2) g
        (y, g'') = randomR (y1, y2) g'
     in (V2 x y, g'')
  random g =
    let (x, g')  = random g
        (y, g'') = random g'
     in (V2 x y, g'')
