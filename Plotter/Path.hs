module Plotter.Path where

import qualified Data.Vector as V
import qualified Data.List as L
import qualified Data.Set as S
import System.Random
import Control.Monad.State

type Grid a = V.Vector (V.Vector a)
type Coords = (Int, Int)
type Dimensions = (Int, Int)

marks = L.cycle "abcdefghijklmnopqrstuvyz"

path :: Dimensions -> [Coords]
path dims@(width, height) = reverse $ evalState (tree dims [start]) unvisited
  where
    start = (0, 0)
    unvisited = S.delete start allNodes
    allNodes = S.fromList [(r, c) | r <- [0..height-1], c <- [0..width-1]]

tree :: Dimensions -> [Coords] -> State (S.Set Coords) [Coords]
tree dims path@(node:rest) = do
  unvisited <- get
  put (S.delete node unvisited)
  foldM visit path (neighbours unvisited)
  where
    visit path n = tree dims (n:path)
    neighbours unvisited = unvisitedNeighbours dims unvisited node 

shuffle :: [a] -> State StdGen [a]
shuffle as = liftM (V.toList . foldr f v) $ rndIndexes $ length as
  where
    f i acc = let x = acc V.! i; y = acc V.! 0 in set i y (set 0 x acc)
    v = V.fromList as

rndIndexes :: Int -> State StdGen [Int]
rndIndexes n = sequence $ replicate n randomInt
  where
    randomInt = do
      rndGen <- get
      let (i, rndGen') = randomR (0, n- 1) rndGen
        in put rndGen' >> return i

unvisitedNeighbours :: Dimensions -> S.Set Coords -> Coords -> [Coords]
unvisitedNeighbours dims unvisited coords =
  filter (flip S.member unvisited) (neighbours dims coords)

neighbours :: Dimensions -> Coords -> [Coords]
neighbours (w, h) (r, c) = filter onGrid [(r+ro, c+co) | (ro, co) <- offsets]
  where
    onGrid (r, c) = (r >= 0) && (r <= h) && (c >= 0) && (c <= w)

offsets = [(-1,0),(0,-1),(0,1),(1,0)]

toString :: Dimensions -> [Coords] -> String
toString dims path = (L.intercalate eol $ list) ++ eol
  where 
    list = V.toList $ V.map V.toList $ markPath dims (zip path marks)
    eol = "\n"

markPath :: Dimensions -> [((Int, Int), Char)] -> Grid Char
markPath (width, height) = foldr mark (blank width height)
  where
    mark ((row, col), char) = set2 row col char

set :: Int -> a -> V.Vector a -> V.Vector a
set i e v = v V.// [(i, e)]

set2 :: Int -> Int -> a -> Grid a -> Grid a
set2 row col e grid = set row (set col e (grid V.! row)) grid

blank :: Int -> Int -> V.Vector (V.Vector Char)
blank width height = V.replicate height row
  where
    row = V.replicate width '-'