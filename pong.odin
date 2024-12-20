package main

import libc "core:c/libc"
import "core:strconv"
import "core:strings"
import "core:fmt"
import rl "vendor:raylib"

SCREENW :: 1800
SCREENH :: 1100

PADDLEW :: 15
PADDLEH :: 150

PADDLE_SPEED :: 5
BALL_SPEED :: 10

GameState :: struct {
	players: [2]Player,
	ball:    Ball,
}

Player :: struct {
	pos:   rl.Vector2,
	score: i32,
}

Ball :: struct {
	pos:   rl.Vector2,
	dir:   rl.Vector2,
	speed: i32,
}

gameState := GameState {
	[2]Player {
		Player{rl.Vector2{25, SCREENH / 2}, 0},
		Player{rl.Vector2{SCREENW - PADDLEW - 25, SCREENH / 2}, 0},
	},
	Ball{rl.Vector2{SCREENW / 2, SCREENH / 2}, rl.Vector2{-1, 1}, BALL_SPEED},
}

resetBall :: proc(gs: ^GameState) {
	gs.ball = Ball{rl.Vector2{SCREENW / 2, SCREENH / 2}, rl.Vector2{-1, 1}, BALL_SPEED}
}

update :: proc(gs: ^GameState) {
	updatePlayers(&gs.players)
	updateBall(&gs.ball, &gs.players)
}


updatePlayers :: proc(players: ^[2]Player) {
	player1 := &players[0]
	player2 := &players[1]

	// Keys	
	if rl.IsKeyDown(.W) && player1.pos.y > PADDLEH / 2 {
		player1.pos.y -= PADDLE_SPEED
	}
	if rl.IsKeyDown(.S) && player1.pos.y < SCREENH - PADDLEH / 2 {
		player1.pos.y += PADDLE_SPEED
	}
	if rl.IsKeyDown(.O) && player2.pos.y > PADDLEH / 2 {
		player2.pos.y -= PADDLE_SPEED
	}
	if rl.IsKeyDown(.L) && player2.pos.y < SCREENH - PADDLEH / 2 {
		player2.pos.y += PADDLE_SPEED
	}
}

// TODO: Fix magic number & add sections to paddle to effect speed of ball
checkPlayerCollision :: proc(b: Ball, p: Player) -> bool {
	closestX := libc.fmaxf(p.pos.x, libc.fminf(b.pos.x, p.pos.x + PADDLEW))
	closestY := libc.fmaxf(p.pos.y - PADDLEH / 2, libc.fminf(b.pos.y, p.pos.y + PADDLEH / 2))

	distanceX := b.pos.x - closestX
	distanceY := b.pos.y - closestY

	// Magic number
	return (distanceX * distanceX + distanceY * distanceY) <= (4.5 * 4.5)
}

updateBall :: proc(ball: ^Ball, players: ^[2]Player) {
	// Top and bottom collision
	if ((ball.pos.y <= 0) || (ball.pos.y >= SCREENH)) {
		ball.dir.y *= -1
	}

  // Left and right collision
	leftGoal := ball.pos.x <= 0
	rightGoal := ball.pos.x >= SCREENW
	if leftGoal || rightGoal {
		resetBall(&gameState)
		if leftGoal {
			players[1].score += 1
		} else {
			players[0].score += 1
		}
	}

	if checkPlayerCollision(ball^, players[0]) || checkPlayerCollision(ball^, players[1]) {
		ball.dir.x *= -1
	}

	// Update ball
	ball.pos.x += f32(ball.speed) * ball.dir.x
	ball.pos.y += f32(ball.speed) * ball.dir.y
}

draw :: proc(gs: GameState) {
	drawBall(gs.ball)
	drawPlayer(gs.players[0])
	drawPlayer(gs.players[1])
}

drawBall :: proc(b: Ball) {
	rl.DrawCircle(i32(b.pos.x), i32(b.pos.y), 9, rl.WHITE)
}

drawPlayer :: proc(p: Player) {
  buf: [4]byte
  score := strconv.itoa(buf[:], int(p.score))
  scoreStr, _ := strings.clone_to_cstring(score)

  if p.pos.x < SCREENW / 2 {
    rl.DrawText(scoreStr, i32(p.pos.x + 100), 20, 20, rl.WHITE)
  } else {
    rl.DrawText(scoreStr, i32(p.pos.x - 100), 20, 20, rl.WHITE)
  }
	rl.DrawRectangle(i32(p.pos.x), i32(p.pos.y) - (PADDLEH / 2), PADDLEW, PADDLEH, rl.WHITE)
}

main :: proc() {
	rl.InitWindow(SCREENW, SCREENH, "pong")
  rl.SetTargetFPS(120)
	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)

		update(&gameState)

		draw(gameState)

		rl.EndDrawing()
	}
	rl.CloseWindow()
}
