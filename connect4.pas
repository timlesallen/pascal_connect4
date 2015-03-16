{
Connect 4 - Copyright (C) 1999  Andrew Clausen

This program is free software.  It is released under the terms of the
GNU General Public Licence as published by the Free Software Foundation, Inc.
which can be obtained from www.gnu.org.

This program comes with ABSOLUTELY NO WARRANTY, not even an implied
warranty of merchantability, or fitness for a particular purpose.
}
program connect4;

uses crt;

const EMPTY = 0;
      RED = 1;
      YELLOW = 2;

const PLAYER_COMPUTER   = 0;
      COMPUTER_PLAYER   = 1;
      PLAYER_PLAYER     = 2;
      COMPUTER_COMPUTER = 3;
      QUIT              = 4;

const weight : array [1..7, 1..6] of integer =
{
      (
          (  0,  0, 20, 30, 30, 20),
          (  0, 40, 40, 50, 60, 60),
          ( 50, 60, 70, 90, 90, 80),
          ( 80, 90,100,100, 70, 90),
          ( 50, 60, 70, 90, 90, 80),
          (  0, 40, 40, 50, 60, 60),
          (  0,  0, 20, 30, 30, 20)
      );
}
	(
		(  3,   1,   0,  11,  20,  26),
		(  0,  38,  33,  42,  39,  27),
		( 35,  60,  74,  81,  77,  48),
		( 72,  91,  91, 100,  88,  68),
		( 37,  48,  88,  95,  81,  78),
		(  9,  51,  25,  64,  22,  18),
		(  3,   7,   6,  28,  26,  27)
	);

var board: array [1..7, 1..6] of integer;
    do_draw_board : boolean;
    screen : array [0..23, 0..79, 0..1] of byte absolute $B800:0000;

type PMove = ^TMove;
     TMove = record
    col, row: integer;
    score: integer;
end;

procedure clear_screen;
var x, y : integer;
begin
    for y := 0 to 23 do
        for x := 0 to 79 do
        begin
            screen [y, x, 0] := byte (' ');
            screen [y, x, 1] := 7;
        end;
    clrscr;
end;

procedure init_board;
var x, y: integer;
begin
   clear_screen;
   for y := 1 to 6 do
       for x := 1 to 7 do
           board [x, y] := EMPTY;
end;

procedure draw_board;
var x, y: integer;
    colour: integer;
begin
   for x := 22 to 51 do
       for y := 4 to 16 do
       begin
           screen [y, x, 0] := 219;
           if (y mod 2 = 0) or (x mod 4 > 1) then
               screen [y, x, 1] := 1
           else
               screen [y, x, 1] := 0;
       end;

   for y := 1 to 6 do
   begin
       for x := 1 to 7 do
       begin
           case board [x, y] of
               EMPTY:  colour := 0;
               RED:    colour := 4;
               YELLOW: colour := 14;
           end;
           screen [3 + y * 2, 20 + x * 4, 1] := colour;
           screen [3 + y * 2, 21 + x * 4, 1] := colour;
       end;
       writeln;
   end;
end;


function drop_piece (column, colour: integer) : integer;
var y: integer;
begin
    for y := 6 downto 1 do
    begin
        if board [column, y] = EMPTY then
        begin
            board [column, y] := colour;
            drop_piece := colour;
            exit;
        end;
    end;

    if do_draw_board then
    begin
        clear_screen;
        writeln;
        draw_board;
        delay (500);
    end;
end;

procedure undrop_piece (column: integer);
var y: integer;
begin
   y := 1;
   while board [column, y] = EMPTY do
       y := y + 1;
   board [column, y] := EMPTY;

   if do_draw_board then
   begin
       clear_screen;
       writeln;
       draw_board;
       delay (500);
   end;
end;

function min (a, b: integer) : integer;
begin
    if a < b then
        min := a
    else
        min := b;
end;

function max (a, b: integer) : integer;
begin
    if a > b then
        max := a
    else
        max := b;
end;

function is_connect_four_vert (x, y, team : integer) : boolean;
var i: integer;
begin
    if y > 3 then
        is_connect_four_vert := false
    else
    begin
        is_connect_four_vert := true;
        for i := y to y + 3 do
            if board [x, i] <> team then
                is_connect_four_vert := false;
    end;
end;

function is_connect_four_horiz (x, y, team : integer) : boolean;
var i, run: integer;
begin
    run := 0;
    is_connect_four_horiz := false;
    for i := max (x - 4, 1) to min (x + 4, 7) do
    begin
        if board [i, y] = team then
        begin
            run := run + 1;
            if run = 4 then
                is_connect_four_horiz := true;
        end
        else run := 0;
    end;
end;

function is_connect_four_ldiag (x, y, team : integer) : boolean;
var pos, start, finish, run : integer;
begin
    start := - min (min (x - 1, y - 1), 3);
    finish := min (min (7 - x, 6 - y), 3);
    run := 0;
    is_connect_four_ldiag := false;
    for pos := start to finish do
    begin
        if board [x + pos, y + pos] = team then
        begin
            run := run + 1;
            if run = 4 then
                is_connect_four_ldiag := true;
        end
        else run := 0;
    end;
end;

function is_connect_four_rdiag (x, y, team : integer) : boolean;
var pos, start, finish, run : integer;
begin
    start := - min (min (x - 1, 6 - y), 3);
    finish := min (min (7 - x, y - 1), 3);
    run := 0;
    is_connect_four_rdiag := false;
    for pos := start to finish do
    begin
        if board [x + pos, y - pos] = team then
        begin
            run := run + 1;
            if run = 4 then
                is_connect_four_rdiag := true;
        end
        else run := 0;
    end;
end;

function is_connect_four_diag (x, y, team : integer) : boolean;
begin
    is_connect_four_diag := is_connect_four_ldiag (x, y, team)
                            or is_connect_four_rdiag (x, y, team);
end;

{ Checks for connect 4, going through (x, y) }
function is_connect_four (x: integer) : boolean;
var team: integer;
    y : integer;
begin
    y := 1;
    while board [x, y] = EMPTY do
        y := y + 1;
    team := board [x, y];
    is_connect_four := is_connect_four_diag (x, y, team)
                       or is_connect_four_vert (x, y, team)
                       or is_connect_four_horiz (x, y, team);
end;

procedure draw_piece (col, team: integer);
var i: integer;
    colour: integer;
begin
    if team = YELLOW then
        colour := 14
    else
        colour := 4;
    screen [2, 20 + col * 4, 0] := 219;
    screen [2, 20 + col * 4 + 1, 0] := 219;
    screen [2, 20 + col * 4, 1] := colour;
    screen [2, 20 + col * 4 + 1, 1] := colour;
end;

function read_spot (team: integer) : integer;
var col: integer;
    key: char;
begin
    col := 4;
    repeat
        clear_screen;
        draw_piece (col, team);
        draw_board;
        key := readkey;
        if key = #0 then
        begin
            case readkey of
                #75: if col > 1 then col := col - 1;
                #77: if col < 7 then col := col + 1;
            end;
        end;
        if key = 'q' then halt;
        if key = 'd' then do_draw_board := not do_draw_board;
    until (key = ' ') and (board [col, 1] = EMPTY);
    read_spot := col;
end;

function other_team (team: integer) : integer;
begin
    if team = RED then
        other_team := YELLOW
    else
        other_team := RED;
end;

var move_result: TMove;

procedure think (team, lookahead : integer);
var x: integer;
    best_move, this_move: TMove;
    a: integer;
begin
    best_move.col := 4;
    best_move.score := -16384;

    for this_move.col := 1 to 7 do
    begin
        if board [this_move.col, 1] = EMPTY then
        begin
            a := this_move.col;
            this_move.row := drop_piece (this_move.col, team);

            if is_connect_four (this_move.col) then
            begin
                 undrop_piece (this_move.col);
                 this_move.score := 16384;
                 move_result := this_move;
                 exit;
            end;

            this_move.score := 0;
            if lookahead > 0 then
            begin
                think (other_team (team), lookahead - 1);
                this_move.score := - move_result.score * 5 div 6;
            end;
            this_move.score := this_move.score
                               + weight [this_move.col, this_move.row];
            undrop_piece (this_move.col);

            if this_move.score > best_move.score then
            begin
                best_move.col := this_move.col;
                best_move.score := this_move.score;
            end;
        end;
    end;

    move_result := best_move;
end;

procedure draw_colour (first_row, last_row, l, r, colour: integer);
var i, j: integer;
begin
    for i := first_row to last_row do
        for j := l to r do
            screen [i, j, 1] := colour;
end;

function menu : integer;
var selected: integer;
    ch: char;
begin
    clear_screen;
    writeln;
    writeln (' Connect 4 - Copyright (C) 1999  Andrew Clausen');
    writeln;
    writeln (' This program is free software.  It is released under the terms of the');
    writeln (' GNU General Public Licence as published by the Free Software Foundation, Inc.');
    writeln (' which can be obtained from www.gnu.org.');
    writeln;
    writeln (' This program comes with ABSOLUTELY NO WARRANTY, not even an implied');
    writeln (' warranty of merchantability, or fitness for a particular purpose.');
    writeln;
    writeln;
    draw_colour (0, 9, 0, 79, 15 + (1 shl 4));

    writeln ('       Human vs Computer');
    writeln ('       Computer vs Human');
    writeln ('       Human vs Human');
    writeln ('       Computer vs Computer');
    writeln ('       Quit');
    draw_colour (11, 15, 5, 30, (15 + 4 shl 4));

    selected := PLAYER_COMPUTER;
    repeat
        draw_colour (11 + selected, 11 + selected, 5, 30, (0 + 7 shl 4));
        ch := readkey;
        if (ch = 'q') or (ch = #27) then halt;
        if ch = #13 then
        begin
            menu := selected;
            exit;
        end;
        if (ch = #0) then
        begin
            draw_colour (11 + selected, 11 + selected, 5, 30, (15 + 4 shl 4));
            case readkey of
            #72: selected := (selected + 4) mod 5;
            #80: selected := (selected + 1) mod 5;
            end;
        end;
    until false;
end;

function do_computer_move (team: integer) : integer;
begin
    clear_screen;
    draw_piece (4, team);
    draw_board;

    think (team, 5);
    do_computer_move := move_result.col;
end;

procedure main_loop;
var team: integer;
    spot, dummy2: integer;
    move_num : integer;
    dummy: char;
    computer_yellow: boolean;
    computer_red: boolean;
begin
    case menu of
    PLAYER_COMPUTER:
        begin
            computer_yellow := false;
            computer_red := true;
        end;
    COMPUTER_PLAYER:
        begin
            computer_yellow := true;
            computer_red := false;
        end;
    COMPUTER_COMPUTER:
        begin
            computer_yellow := true;
            computer_red := true;
        end;
    PLAYER_PLAYER:
        begin
            computer_yellow := false;
            computer_red := false;
        end;
    QUIT:
        begin
            halt;
        end;
    end;

    init_board;
    do_draw_board := false;

    team := RED;
    move_num := 0;
    repeat
        move_num := move_num + 1;
        team := other_team (team);

        if team = YELLOW then
        begin
            if computer_yellow then
                 spot := do_computer_move (team)
            else
                 spot := read_spot (team)
        end
        else
        begin
            if computer_red then
                 spot := do_computer_move (team)
            else
                 spot := read_spot (team)
        end;

        dummy2 := drop_piece (spot, team);
    until is_connect_four (spot) or (move_num = 42);

    clear_screen;
    writeln;
    draw_board;
    writeln;

    if team = RED then
        writeln ('  RED won')
    else
        writeln ('  YELLOW won');
    dummy := readkey;
end;

begin
    while true do main_loop;
end.
