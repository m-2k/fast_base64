-module(fast_base64).

-export([decode/1]).
-compile(inline).
-compile({inline_size, 100}).


decode(Base64) ->
    % Split input binary in two parts: FullPart containing of full Base64 blocks and possibly incomplete LastBlock
    % First, calculate the length of FullPart:
    Size = byte_size(Base64),
    FullBlocksCnt = (Size - 1) div 4,
    FullPartLen = FullBlocksCnt * 4,
    % Then actually split:
    <<FullPart:FullPartLen/binary, LastBlock/binary>> = Base64,
    % Decode full blocks
    DecodedFullBlocks = << <<(decode_full_block(Block))/binary>> || <<Block:4/binary>> <= FullPart>>,
    % ... And append decoded last block
    <<DecodedFullBlocks/binary, (decode_last_block(LastBlock))/binary>>.


%% One-based decode map.
-define(DECODE_MAP,
	{bad,bad,bad,bad,bad,bad,bad,bad,ws,ws,bad,bad,ws,bad,bad, %1-15
	 bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad, %16-31
	 ws,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,62,bad,bad,bad,63, %32-47
	 52,53,54,55,56,57,58,59,60,61,bad,bad,bad,eq,bad,bad, %48-63
	 bad,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,
	 15,16,17,18,19,20,21,22,23,24,25,bad,bad,bad,bad,bad,
	 bad,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,
	 41,42,43,44,45,46,47,48,49,50,51,bad,bad,bad,bad,bad,
	 bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,
	 bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,
	 bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,
	 bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,
	 bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,
	 bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,
	 bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,
	 bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad,bad}).

-define(decode_char(X), element(X, ?DECODE_MAP)).

decode_last_block(<<A:8, B:8>>) ->
    Ad = ?decode_char(A),
    Bd = ?decode_char(B),
    <<Ad:6, (Bd bsr 4):2>>;
decode_last_block(<<A:8, B:8, "=", _/binary>>) ->
    decode_last_block(<<A:8, B:8>>);

decode_last_block(<<A:8, B:8, C:8>>) ->
    Ad = ?decode_char(A),
    Bd = ?decode_char(B),
    Cd = ?decode_char(C),
    <<Ad:6, Bd:6, (Cd bsr 2):4>>;
decode_last_block(<<A:8, B:8, C:8, "=">>) ->
    decode_last_block(<<A:8, B:8, C:8>>);

decode_last_block(<<A:8, B:8, C:8, D:8>>) ->
    decode_full_block(<<A:8, B:8, C:8, D:8>>).

decode_full_block(<<A:8, B:8, C:8, D:8>>) ->
    Ad = ?decode_char(A),
    Bd = ?decode_char(B),
    Cd = ?decode_char(C),
    Dd = ?decode_char(D),
    <<Ad:6, Bd:6, Cd:6, Dd:6>>.

