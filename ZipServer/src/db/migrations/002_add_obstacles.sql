-- ============================================================================
-- ZIP Competitive Puzzle Platform — Database Schema
-- Migration: 002_add_obstacles
-- Add obstacles column to puzzles table
-- ============================================================================

-- Add obstacles column to puzzles table
ALTER TABLE puzzles 
ADD COLUMN IF NOT EXISTS obstacles JSONB DEFAULT '[]'::jsonb;

-- Add comment for documentation
COMMENT ON COLUMN puzzles.obstacles IS 'Array of obstacle cells [{x, y}] that block the path';
