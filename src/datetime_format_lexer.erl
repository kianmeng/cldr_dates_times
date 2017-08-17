-file("/usr/local/Cellar/erlang/20.0/lib/erlang/lib/parsetools-2.1.5/include/leexinc.hrl", 0).
%% The source of this file is part of leex distribution, as such it
%% has the same Copyright as the other files in the leex
%% distribution. The Copyright is defined in the accompanying file
%% COPYRIGHT. However, the resultant scanner generated by leex is the
%% property of the creator of the scanner and is not covered by that
%% Copyright.

-module(datetime_format_lexer).

-export([string/1,string/2,token/2,token/3,tokens/2,tokens/3]).
-export([format_error/1]).

%% User code. This is placed here to allow extra attributes.
-file("src/datetime_format_lexer.xrl", 114).

-import('Elixir.List', [to_string/1]).

count(Chars) -> string:len(Chars).

unquote([_ | Tail]) ->
  [_ | Rev] = lists:reverse(Tail),
  lists:reverse(Rev).

-file("/usr/local/Cellar/erlang/20.0/lib/erlang/lib/parsetools-2.1.5/include/leexinc.hrl", 14).

format_error({illegal,S}) -> ["illegal characters ",io_lib:write_string(S)];
format_error({user,S}) -> S.

string(String) -> string(String, 1).

string(String, Line) -> string(String, Line, String, []).

%% string(InChars, Line, TokenChars, Tokens) ->
%% {ok,Tokens,Line} | {error,ErrorInfo,Line}.
%% Note the line number going into yystate, L0, is line of token
%% start while line number returned is line of token end. We want line
%% of token start.

string([], L, [], Ts) ->                     % No partial tokens!
    {ok,yyrev(Ts),L};
string(Ics0, L0, Tcs, Ts) ->
    case yystate(yystate(), Ics0, L0, 0, reject, 0) of
        {A,Alen,Ics1,L1} ->                  % Accepting end state
            string_cont(Ics1, L1, yyaction(A, Alen, Tcs, L0), Ts);
        {A,Alen,Ics1,L1,_S1} ->              % Accepting transistion state
            string_cont(Ics1, L1, yyaction(A, Alen, Tcs, L0), Ts);
        {reject,_Alen,Tlen,_Ics1,L1,_S1} ->  % After a non-accepting state
            {error,{L0,?MODULE,{illegal,yypre(Tcs, Tlen+1)}},L1};
        {A,Alen,Tlen,_Ics1,L1,_S1} ->
            Tcs1 = yysuf(Tcs, Alen),
            L2 = adjust_line(Tlen, Alen, Tcs1, L1),
            string_cont(Tcs1, L2, yyaction(A, Alen, Tcs, L0), Ts)
    end.

%% string_cont(RestChars, Line, Token, Tokens)
%% Test for and remove the end token wrapper. Push back characters
%% are prepended to RestChars.

-dialyzer({nowarn_function, string_cont/4}).

string_cont(Rest, Line, {token,T}, Ts) ->
    string(Rest, Line, Rest, [T|Ts]);
string_cont(Rest, Line, {token,T,Push}, Ts) ->
    NewRest = Push ++ Rest,
    string(NewRest, Line, NewRest, [T|Ts]);
string_cont(Rest, Line, {end_token,T}, Ts) ->
    string(Rest, Line, Rest, [T|Ts]);
string_cont(Rest, Line, {end_token,T,Push}, Ts) ->
    NewRest = Push ++ Rest,
    string(NewRest, Line, NewRest, [T|Ts]);
string_cont(Rest, Line, skip_token, Ts) ->
    string(Rest, Line, Rest, Ts);
string_cont(Rest, Line, {skip_token,Push}, Ts) ->
    NewRest = Push ++ Rest,
    string(NewRest, Line, NewRest, Ts);
string_cont(_Rest, Line, {error,S}, _Ts) ->
    {error,{Line,?MODULE,{user,S}},Line}.

%% token(Continuation, Chars) ->
%% token(Continuation, Chars, Line) ->
%% {more,Continuation} | {done,ReturnVal,RestChars}.
%% Must be careful when re-entering to append the latest characters to the
%% after characters in an accept. The continuation is:
%% {token,State,CurrLine,TokenChars,TokenLen,TokenLine,AccAction,AccLen}

token(Cont, Chars) -> token(Cont, Chars, 1).

token([], Chars, Line) ->
    token(yystate(), Chars, Line, Chars, 0, Line, reject, 0);
token({token,State,Line,Tcs,Tlen,Tline,Action,Alen}, Chars, _) ->
    token(State, Chars, Line, Tcs ++ Chars, Tlen, Tline, Action, Alen).

%% token(State, InChars, Line, TokenChars, TokenLen, TokenLine,
%% AcceptAction, AcceptLen) ->
%% {more,Continuation} | {done,ReturnVal,RestChars}.
%% The argument order is chosen to be more efficient.

token(S0, Ics0, L0, Tcs, Tlen0, Tline, A0, Alen0) ->
    case yystate(S0, Ics0, L0, Tlen0, A0, Alen0) of
        %% Accepting end state, we have a token.
        {A1,Alen1,Ics1,L1} ->
            token_cont(Ics1, L1, yyaction(A1, Alen1, Tcs, Tline));
        %% Accepting transition state, can take more chars.
        {A1,Alen1,[],L1,S1} ->                  % Need more chars to check
            {more,{token,S1,L1,Tcs,Alen1,Tline,A1,Alen1}};
        {A1,Alen1,Ics1,L1,_S1} ->               % Take what we got
            token_cont(Ics1, L1, yyaction(A1, Alen1, Tcs, Tline));
        %% After a non-accepting state, maybe reach accept state later.
        {A1,Alen1,Tlen1,[],L1,S1} ->            % Need more chars to check
            {more,{token,S1,L1,Tcs,Tlen1,Tline,A1,Alen1}};
        {reject,_Alen1,Tlen1,eof,L1,_S1} ->     % No token match
            %% Check for partial token which is error.
            Ret = if Tlen1 > 0 -> {error,{Tline,?MODULE,
                                          %% Skip eof tail in Tcs.
                                          {illegal,yypre(Tcs, Tlen1)}},L1};
                     true -> {eof,L1}
                  end,
            {done,Ret,eof};
        {reject,_Alen1,Tlen1,Ics1,L1,_S1} ->    % No token match
            Error = {Tline,?MODULE,{illegal,yypre(Tcs, Tlen1+1)}},
            {done,{error,Error,L1},Ics1};
        {A1,Alen1,Tlen1,_Ics1,L1,_S1} ->       % Use last accept match
            Tcs1 = yysuf(Tcs, Alen1),
            L2 = adjust_line(Tlen1, Alen1, Tcs1, L1),
            token_cont(Tcs1, L2, yyaction(A1, Alen1, Tcs, Tline))
    end.

%% token_cont(RestChars, Line, Token)
%% If we have a token or error then return done, else if we have a
%% skip_token then continue.

-dialyzer({nowarn_function, token_cont/3}).

token_cont(Rest, Line, {token,T}) ->
    {done,{ok,T,Line},Rest};
token_cont(Rest, Line, {token,T,Push}) ->
    NewRest = Push ++ Rest,
    {done,{ok,T,Line},NewRest};
token_cont(Rest, Line, {end_token,T}) ->
    {done,{ok,T,Line},Rest};
token_cont(Rest, Line, {end_token,T,Push}) ->
    NewRest = Push ++ Rest,
    {done,{ok,T,Line},NewRest};
token_cont(Rest, Line, skip_token) ->
    token(yystate(), Rest, Line, Rest, 0, Line, reject, 0);
token_cont(Rest, Line, {skip_token,Push}) ->
    NewRest = Push ++ Rest,
    token(yystate(), NewRest, Line, NewRest, 0, Line, reject, 0);
token_cont(Rest, Line, {error,S}) ->
    {done,{error,{Line,?MODULE,{user,S}},Line},Rest}.

%% tokens(Continuation, Chars, Line) ->
%% {more,Continuation} | {done,ReturnVal,RestChars}.
%% Must be careful when re-entering to append the latest characters to the
%% after characters in an accept. The continuation is:
%% {tokens,State,CurrLine,TokenChars,TokenLen,TokenLine,Tokens,AccAction,AccLen}
%% {skip_tokens,State,CurrLine,TokenChars,TokenLen,TokenLine,Error,AccAction,AccLen}

tokens(Cont, Chars) -> tokens(Cont, Chars, 1).

tokens([], Chars, Line) ->
    tokens(yystate(), Chars, Line, Chars, 0, Line, [], reject, 0);
tokens({tokens,State,Line,Tcs,Tlen,Tline,Ts,Action,Alen}, Chars, _) ->
    tokens(State, Chars, Line, Tcs ++ Chars, Tlen, Tline, Ts, Action, Alen);
tokens({skip_tokens,State,Line,Tcs,Tlen,Tline,Error,Action,Alen}, Chars, _) ->
    skip_tokens(State, Chars, Line, Tcs ++ Chars, Tlen, Tline, Error, Action, Alen).

%% tokens(State, InChars, Line, TokenChars, TokenLen, TokenLine, Tokens,
%% AcceptAction, AcceptLen) ->
%% {more,Continuation} | {done,ReturnVal,RestChars}.

tokens(S0, Ics0, L0, Tcs, Tlen0, Tline, Ts, A0, Alen0) ->
    case yystate(S0, Ics0, L0, Tlen0, A0, Alen0) of
        %% Accepting end state, we have a token.
        {A1,Alen1,Ics1,L1} ->
            tokens_cont(Ics1, L1, yyaction(A1, Alen1, Tcs, Tline), Ts);
        %% Accepting transition state, can take more chars.
        {A1,Alen1,[],L1,S1} ->                  % Need more chars to check
            {more,{tokens,S1,L1,Tcs,Alen1,Tline,Ts,A1,Alen1}};
        {A1,Alen1,Ics1,L1,_S1} ->               % Take what we got
            tokens_cont(Ics1, L1, yyaction(A1, Alen1, Tcs, Tline), Ts);
        %% After a non-accepting state, maybe reach accept state later.
        {A1,Alen1,Tlen1,[],L1,S1} ->            % Need more chars to check
            {more,{tokens,S1,L1,Tcs,Tlen1,Tline,Ts,A1,Alen1}};
        {reject,_Alen1,Tlen1,eof,L1,_S1} ->     % No token match
            %% Check for partial token which is error, no need to skip here.
            Ret = if Tlen1 > 0 -> {error,{Tline,?MODULE,
                                          %% Skip eof tail in Tcs.
                                          {illegal,yypre(Tcs, Tlen1)}},L1};
                     Ts == [] -> {eof,L1};
                     true -> {ok,yyrev(Ts),L1}
                  end,
            {done,Ret,eof};
        {reject,_Alen1,Tlen1,_Ics1,L1,_S1} ->
            %% Skip rest of tokens.
            Error = {L1,?MODULE,{illegal,yypre(Tcs, Tlen1+1)}},
            skip_tokens(yysuf(Tcs, Tlen1+1), L1, Error);
        {A1,Alen1,Tlen1,_Ics1,L1,_S1} ->
            Token = yyaction(A1, Alen1, Tcs, Tline),
            Tcs1 = yysuf(Tcs, Alen1),
            L2 = adjust_line(Tlen1, Alen1, Tcs1, L1),
            tokens_cont(Tcs1, L2, Token, Ts)
    end.

%% tokens_cont(RestChars, Line, Token, Tokens)
%% If we have an end_token or error then return done, else if we have
%% a token then save it and continue, else if we have a skip_token
%% just continue.

-dialyzer({nowarn_function, tokens_cont/4}).

tokens_cont(Rest, Line, {token,T}, Ts) ->
    tokens(yystate(), Rest, Line, Rest, 0, Line, [T|Ts], reject, 0);
tokens_cont(Rest, Line, {token,T,Push}, Ts) ->
    NewRest = Push ++ Rest,
    tokens(yystate(), NewRest, Line, NewRest, 0, Line, [T|Ts], reject, 0);
tokens_cont(Rest, Line, {end_token,T}, Ts) ->
    {done,{ok,yyrev(Ts, [T]),Line},Rest};
tokens_cont(Rest, Line, {end_token,T,Push}, Ts) ->
    NewRest = Push ++ Rest,
    {done,{ok,yyrev(Ts, [T]),Line},NewRest};
tokens_cont(Rest, Line, skip_token, Ts) ->
    tokens(yystate(), Rest, Line, Rest, 0, Line, Ts, reject, 0);
tokens_cont(Rest, Line, {skip_token,Push}, Ts) ->
    NewRest = Push ++ Rest,
    tokens(yystate(), NewRest, Line, NewRest, 0, Line, Ts, reject, 0);
tokens_cont(Rest, Line, {error,S}, _Ts) ->
    skip_tokens(Rest, Line, {Line,?MODULE,{user,S}}).

%%skip_tokens(InChars, Line, Error) -> {done,{error,Error,Line},Ics}.
%% Skip tokens until an end token, junk everything and return the error.

skip_tokens(Ics, Line, Error) ->
    skip_tokens(yystate(), Ics, Line, Ics, 0, Line, Error, reject, 0).

%% skip_tokens(State, InChars, Line, TokenChars, TokenLen, TokenLine, Tokens,
%% AcceptAction, AcceptLen) ->
%% {more,Continuation} | {done,ReturnVal,RestChars}.

skip_tokens(S0, Ics0, L0, Tcs, Tlen0, Tline, Error, A0, Alen0) ->
    case yystate(S0, Ics0, L0, Tlen0, A0, Alen0) of
        {A1,Alen1,Ics1,L1} ->                  % Accepting end state
            skip_cont(Ics1, L1, yyaction(A1, Alen1, Tcs, Tline), Error);
        {A1,Alen1,[],L1,S1} ->                 % After an accepting state
            {more,{skip_tokens,S1,L1,Tcs,Alen1,Tline,Error,A1,Alen1}};
        {A1,Alen1,Ics1,L1,_S1} ->
            skip_cont(Ics1, L1, yyaction(A1, Alen1, Tcs, Tline), Error);
        {A1,Alen1,Tlen1,[],L1,S1} ->           % After a non-accepting state
            {more,{skip_tokens,S1,L1,Tcs,Tlen1,Tline,Error,A1,Alen1}};
        {reject,_Alen1,_Tlen1,eof,L1,_S1} ->
            {done,{error,Error,L1},eof};
        {reject,_Alen1,Tlen1,_Ics1,L1,_S1} ->
            skip_tokens(yysuf(Tcs, Tlen1+1), L1, Error);
        {A1,Alen1,Tlen1,_Ics1,L1,_S1} ->
            Token = yyaction(A1, Alen1, Tcs, Tline),
            Tcs1 = yysuf(Tcs, Alen1),
            L2 = adjust_line(Tlen1, Alen1, Tcs1, L1),
            skip_cont(Tcs1, L2, Token, Error)
    end.

%% skip_cont(RestChars, Line, Token, Error)
%% Skip tokens until we have an end_token or error then return done
%% with the original rror.

-dialyzer({nowarn_function, skip_cont/4}).

skip_cont(Rest, Line, {token,_T}, Error) ->
    skip_tokens(yystate(), Rest, Line, Rest, 0, Line, Error, reject, 0);
skip_cont(Rest, Line, {token,_T,Push}, Error) ->
    NewRest = Push ++ Rest,
    skip_tokens(yystate(), NewRest, Line, NewRest, 0, Line, Error, reject, 0);
skip_cont(Rest, Line, {end_token,_T}, Error) ->
    {done,{error,Error,Line},Rest};
skip_cont(Rest, Line, {end_token,_T,Push}, Error) ->
    NewRest = Push ++ Rest,
    {done,{error,Error,Line},NewRest};
skip_cont(Rest, Line, skip_token, Error) ->
    skip_tokens(yystate(), Rest, Line, Rest, 0, Line, Error, reject, 0);
skip_cont(Rest, Line, {skip_token,Push}, Error) ->
    NewRest = Push ++ Rest,
    skip_tokens(yystate(), NewRest, Line, NewRest, 0, Line, Error, reject, 0);
skip_cont(Rest, Line, {error,_S}, Error) ->
    skip_tokens(yystate(), Rest, Line, Rest, 0, Line, Error, reject, 0).

yyrev(List) -> lists:reverse(List).
yyrev(List, Tail) -> lists:reverse(List, Tail).
yypre(List, N) -> lists:sublist(List, N).
yysuf(List, N) -> lists:nthtail(N, List).

%% adjust_line(TokenLength, AcceptLength, Chars, Line) -> NewLine
%% Make sure that newlines in Chars are not counted twice.
%% Line has been updated with respect to newlines in the prefix of
%% Chars consisting of (TokenLength - AcceptLength) characters.

adjust_line(N, N, _Cs, L) -> L;
adjust_line(T, A, [$\n|Cs], L) ->
    adjust_line(T-1, A, Cs, L-1);
adjust_line(T, A, [_|Cs], L) ->
    adjust_line(T-1, A, Cs, L).

%% yystate() -> InitialState.
%% yystate(State, InChars, Line, CurrTokLen, AcceptAction, AcceptLen) ->
%% {Action, AcceptLen, RestChars, Line} |
%% {Action, AcceptLen, RestChars, Line, State} |
%% {reject, AcceptLen, CurrTokLen, RestChars, Line, State} |
%% {Action, AcceptLen, CurrTokLen, RestChars, Line, State}.
%% Generated state transition functions. The non-accepting end state
%% return signal either an unrecognised character or end of current
%% input.

-file("src/datetime_format_lexer.erl", 311).
yystate() -> 44.

yystate(45, [124|Ics], Line, Tlen, _, _) ->
    yystate(45, Ics, Line, Tlen+1, 39, Tlen);
yystate(45, [10|Ics], Line, Tlen, _, _) ->
    yystate(45, Ics, Line+1, Tlen+1, 39, Tlen);
yystate(45, [C|Ics], Line, Tlen, _, _) when C >= 0, C =< 9 ->
    yystate(45, Ics, Line, Tlen+1, 39, Tlen);
yystate(45, [C|Ics], Line, Tlen, _, _) when C >= 11, C =< 38 ->
    yystate(45, Ics, Line, Tlen+1, 39, Tlen);
yystate(45, [C|Ics], Line, Tlen, _, _) when C >= 40, C =< 64 ->
    yystate(45, Ics, Line, Tlen+1, 39, Tlen);
yystate(45, [C|Ics], Line, Tlen, _, _) when C >= 91, C =< 96 ->
    yystate(45, Ics, Line, Tlen+1, 39, Tlen);
yystate(45, [C|Ics], Line, Tlen, _, _) when C >= 126 ->
    yystate(45, Ics, Line, Tlen+1, 39, Tlen);
yystate(45, Ics, Line, Tlen, _, _) ->
    {39,Tlen,Ics,Line,45};
yystate(44, [124|Ics], Line, Tlen, Action, Alen) ->
    yystate(45, Ics, Line, Tlen+1, Action, Alen);
yystate(44, [123|Ics], Line, Tlen, Action, Alen) ->
    yystate(42, Ics, Line, Tlen+1, Action, Alen);
yystate(44, [122|Ics], Line, Tlen, Action, Alen) ->
    yystate(32, Ics, Line, Tlen+1, Action, Alen);
yystate(44, [121|Ics], Line, Tlen, Action, Alen) ->
    yystate(30, Ics, Line, Tlen+1, Action, Alen);
yystate(44, [120|Ics], Line, Tlen, Action, Alen) ->
    yystate(28, Ics, Line, Tlen+1, Action, Alen);
yystate(44, [119|Ics], Line, Tlen, Action, Alen) ->
    yystate(26, Ics, Line, Tlen+1, Action, Alen);
yystate(44, [118|Ics], Line, Tlen, Action, Alen) ->
    yystate(24, Ics, Line, Tlen+1, Action, Alen);
yystate(44, [117|Ics], Line, Tlen, Action, Alen) ->
    yystate(22, Ics, Line, Tlen+1, Action, Alen);
yystate(44, [115|Ics], Line, Tlen, Action, Alen) ->
    yystate(20, Ics, Line, Tlen+1, Action, Alen);
yystate(44, [114|Ics], Line, Tlen, Action, Alen) ->
    yystate(18, Ics, Line, Tlen+1, Action, Alen);
yystate(44, [113|Ics], Line, Tlen, Action, Alen) ->
    yystate(16, Ics, Line, Tlen+1, Action, Alen);
yystate(44, [109|Ics], Line, Tlen, Action, Alen) ->
    yystate(14, Ics, Line, Tlen+1, Action, Alen);
yystate(44, [107|Ics], Line, Tlen, Action, Alen) ->
    yystate(12, Ics, Line, Tlen+1, Action, Alen);
yystate(44, [104|Ics], Line, Tlen, Action, Alen) ->
    yystate(10, Ics, Line, Tlen+1, Action, Alen);
yystate(44, [101|Ics], Line, Tlen, Action, Alen) ->
    yystate(8, Ics, Line, Tlen+1, Action, Alen);
yystate(44, [100|Ics], Line, Tlen, Action, Alen) ->
    yystate(6, Ics, Line, Tlen+1, Action, Alen);
yystate(44, [99|Ics], Line, Tlen, Action, Alen) ->
    yystate(4, Ics, Line, Tlen+1, Action, Alen);
yystate(44, [98|Ics], Line, Tlen, Action, Alen) ->
    yystate(2, Ics, Line, Tlen+1, Action, Alen);
yystate(44, [97|Ics], Line, Tlen, Action, Alen) ->
    yystate(0, Ics, Line, Tlen+1, Action, Alen);
yystate(44, [90|Ics], Line, Tlen, Action, Alen) ->
    yystate(1, Ics, Line, Tlen+1, Action, Alen);
yystate(44, [89|Ics], Line, Tlen, Action, Alen) ->
    yystate(3, Ics, Line, Tlen+1, Action, Alen);
yystate(44, [88|Ics], Line, Tlen, Action, Alen) ->
    yystate(5, Ics, Line, Tlen+1, Action, Alen);
yystate(44, [87|Ics], Line, Tlen, Action, Alen) ->
    yystate(7, Ics, Line, Tlen+1, Action, Alen);
yystate(44, [86|Ics], Line, Tlen, Action, Alen) ->
    yystate(9, Ics, Line, Tlen+1, Action, Alen);
yystate(44, [85|Ics], Line, Tlen, Action, Alen) ->
    yystate(11, Ics, Line, Tlen+1, Action, Alen);
yystate(44, [83|Ics], Line, Tlen, Action, Alen) ->
    yystate(13, Ics, Line, Tlen+1, Action, Alen);
yystate(44, [81|Ics], Line, Tlen, Action, Alen) ->
    yystate(15, Ics, Line, Tlen+1, Action, Alen);
yystate(44, [79|Ics], Line, Tlen, Action, Alen) ->
    yystate(17, Ics, Line, Tlen+1, Action, Alen);
yystate(44, [77|Ics], Line, Tlen, Action, Alen) ->
    yystate(19, Ics, Line, Tlen+1, Action, Alen);
yystate(44, [76|Ics], Line, Tlen, Action, Alen) ->
    yystate(21, Ics, Line, Tlen+1, Action, Alen);
yystate(44, [75|Ics], Line, Tlen, Action, Alen) ->
    yystate(23, Ics, Line, Tlen+1, Action, Alen);
yystate(44, [72|Ics], Line, Tlen, Action, Alen) ->
    yystate(25, Ics, Line, Tlen+1, Action, Alen);
yystate(44, [71|Ics], Line, Tlen, Action, Alen) ->
    yystate(27, Ics, Line, Tlen+1, Action, Alen);
yystate(44, [70|Ics], Line, Tlen, Action, Alen) ->
    yystate(29, Ics, Line, Tlen+1, Action, Alen);
yystate(44, [69|Ics], Line, Tlen, Action, Alen) ->
    yystate(31, Ics, Line, Tlen+1, Action, Alen);
yystate(44, [68|Ics], Line, Tlen, Action, Alen) ->
    yystate(33, Ics, Line, Tlen+1, Action, Alen);
yystate(44, [66|Ics], Line, Tlen, Action, Alen) ->
    yystate(35, Ics, Line, Tlen+1, Action, Alen);
yystate(44, [39|Ics], Line, Tlen, Action, Alen) ->
    yystate(37, Ics, Line, Tlen+1, Action, Alen);
yystate(44, [10|Ics], Line, Tlen, Action, Alen) ->
    yystate(45, Ics, Line+1, Tlen+1, Action, Alen);
yystate(44, [C|Ics], Line, Tlen, Action, Alen) when C >= 0, C =< 9 ->
    yystate(45, Ics, Line, Tlen+1, Action, Alen);
yystate(44, [C|Ics], Line, Tlen, Action, Alen) when C >= 11, C =< 38 ->
    yystate(45, Ics, Line, Tlen+1, Action, Alen);
yystate(44, [C|Ics], Line, Tlen, Action, Alen) when C >= 40, C =< 64 ->
    yystate(45, Ics, Line, Tlen+1, Action, Alen);
yystate(44, [C|Ics], Line, Tlen, Action, Alen) when C >= 91, C =< 96 ->
    yystate(45, Ics, Line, Tlen+1, Action, Alen);
yystate(44, [C|Ics], Line, Tlen, Action, Alen) when C >= 126 ->
    yystate(45, Ics, Line, Tlen+1, Action, Alen);
yystate(44, Ics, Line, Tlen, Action, Alen) ->
    {Action,Alen,Tlen,Ics,Line,44};
yystate(43, Ics, Line, Tlen, _, _) ->
    {37,Tlen,Ics,Line};
yystate(42, [49|Ics], Line, Tlen, Action, Alen) ->
    yystate(40, Ics, Line, Tlen+1, Action, Alen);
yystate(42, [48|Ics], Line, Tlen, Action, Alen) ->
    yystate(36, Ics, Line, Tlen+1, Action, Alen);
yystate(42, Ics, Line, Tlen, Action, Alen) ->
    {Action,Alen,Tlen,Ics,Line,42};
yystate(41, [39|Ics], Line, Tlen, Action, Alen) ->
    yystate(43, Ics, Line, Tlen+1, Action, Alen);
yystate(41, [10|Ics], Line, Tlen, Action, Alen) ->
    yystate(41, Ics, Line+1, Tlen+1, Action, Alen);
yystate(41, [C|Ics], Line, Tlen, Action, Alen) when C >= 0, C =< 9 ->
    yystate(41, Ics, Line, Tlen+1, Action, Alen);
yystate(41, [C|Ics], Line, Tlen, Action, Alen) when C >= 11, C =< 38 ->
    yystate(41, Ics, Line, Tlen+1, Action, Alen);
yystate(41, [C|Ics], Line, Tlen, Action, Alen) when C >= 40 ->
    yystate(41, Ics, Line, Tlen+1, Action, Alen);
yystate(41, Ics, Line, Tlen, Action, Alen) ->
    {Action,Alen,Tlen,Ics,Line,41};
yystate(40, [125|Ics], Line, Tlen, Action, Alen) ->
    yystate(38, Ics, Line, Tlen+1, Action, Alen);
yystate(40, Ics, Line, Tlen, Action, Alen) ->
    {Action,Alen,Tlen,Ics,Line,40};
yystate(39, Ics, Line, Tlen, _, _) ->
    {38,Tlen,Ics,Line};
yystate(38, Ics, Line, Tlen, _, _) ->
    {9,Tlen,Ics,Line};
yystate(37, [39|Ics], Line, Tlen, Action, Alen) ->
    yystate(39, Ics, Line, Tlen+1, Action, Alen);
yystate(37, [10|Ics], Line, Tlen, Action, Alen) ->
    yystate(41, Ics, Line+1, Tlen+1, Action, Alen);
yystate(37, [C|Ics], Line, Tlen, Action, Alen) when C >= 0, C =< 9 ->
    yystate(41, Ics, Line, Tlen+1, Action, Alen);
yystate(37, [C|Ics], Line, Tlen, Action, Alen) when C >= 11, C =< 38 ->
    yystate(41, Ics, Line, Tlen+1, Action, Alen);
yystate(37, [C|Ics], Line, Tlen, Action, Alen) when C >= 40 ->
    yystate(41, Ics, Line, Tlen+1, Action, Alen);
yystate(37, Ics, Line, Tlen, Action, Alen) ->
    {Action,Alen,Tlen,Ics,Line,37};
yystate(36, [125|Ics], Line, Tlen, Action, Alen) ->
    yystate(34, Ics, Line, Tlen+1, Action, Alen);
yystate(36, Ics, Line, Tlen, Action, Alen) ->
    {Action,Alen,Tlen,Ics,Line,36};
yystate(35, [66|Ics], Line, Tlen, _, _) ->
    yystate(35, Ics, Line, Tlen+1, 22, Tlen);
yystate(35, Ics, Line, Tlen, _, _) ->
    {22,Tlen,Ics,Line,35};
yystate(34, Ics, Line, Tlen, _, _) ->
    {8,Tlen,Ics,Line};
yystate(33, [68|Ics], Line, Tlen, _, _) ->
    yystate(33, Ics, Line, Tlen+1, 15, Tlen);
yystate(33, Ics, Line, Tlen, _, _) ->
    {15,Tlen,Ics,Line,33};
yystate(32, [122|Ics], Line, Tlen, _, _) ->
    yystate(32, Ics, Line, Tlen+1, 30, Tlen);
yystate(32, Ics, Line, Tlen, _, _) ->
    {30,Tlen,Ics,Line,32};
yystate(31, [69|Ics], Line, Tlen, _, _) ->
    yystate(31, Ics, Line, Tlen+1, 17, Tlen);
yystate(31, Ics, Line, Tlen, _, _) ->
    {17,Tlen,Ics,Line,31};
yystate(30, [121|Ics], Line, Tlen, _, _) ->
    yystate(30, Ics, Line, Tlen+1, 1, Tlen);
yystate(30, Ics, Line, Tlen, _, _) ->
    {1,Tlen,Ics,Line,30};
yystate(29, [70|Ics], Line, Tlen, _, _) ->
    yystate(29, Ics, Line, Tlen+1, 16, Tlen);
yystate(29, Ics, Line, Tlen, _, _) ->
    {16,Tlen,Ics,Line,29};
yystate(28, [120|Ics], Line, Tlen, _, _) ->
    yystate(28, Ics, Line, Tlen+1, 36, Tlen);
yystate(28, Ics, Line, Tlen, _, _) ->
    {36,Tlen,Ics,Line,28};
yystate(27, [71|Ics], Line, Tlen, _, _) ->
    yystate(27, Ics, Line, Tlen+1, 0, Tlen);
yystate(27, Ics, Line, Tlen, _, _) ->
    {0,Tlen,Ics,Line,27};
yystate(26, [119|Ics], Line, Tlen, _, _) ->
    yystate(26, Ics, Line, Tlen+1, 12, Tlen);
yystate(26, Ics, Line, Tlen, _, _) ->
    {12,Tlen,Ics,Line,26};
yystate(25, [72|Ics], Line, Tlen, _, _) ->
    yystate(25, Ics, Line, Tlen+1, 26, Tlen);
yystate(25, Ics, Line, Tlen, _, _) ->
    {26,Tlen,Ics,Line,25};
yystate(24, [118|Ics], Line, Tlen, _, _) ->
    yystate(24, Ics, Line, Tlen+1, 33, Tlen);
yystate(24, Ics, Line, Tlen, _, _) ->
    {33,Tlen,Ics,Line,24};
yystate(23, [75|Ics], Line, Tlen, _, _) ->
    yystate(23, Ics, Line, Tlen+1, 24, Tlen);
yystate(23, Ics, Line, Tlen, _, _) ->
    {24,Tlen,Ics,Line,23};
yystate(22, [117|Ics], Line, Tlen, _, _) ->
    yystate(22, Ics, Line, Tlen+1, 3, Tlen);
yystate(22, Ics, Line, Tlen, _, _) ->
    {3,Tlen,Ics,Line,22};
yystate(21, [76|Ics], Line, Tlen, _, _) ->
    yystate(21, Ics, Line, Tlen+1, 11, Tlen);
yystate(21, Ics, Line, Tlen, _, _) ->
    {11,Tlen,Ics,Line,21};
yystate(20, [115|Ics], Line, Tlen, _, _) ->
    yystate(20, Ics, Line, Tlen+1, 28, Tlen);
yystate(20, Ics, Line, Tlen, _, _) ->
    {28,Tlen,Ics,Line,20};
yystate(19, [77|Ics], Line, Tlen, _, _) ->
    yystate(19, Ics, Line, Tlen+1, 10, Tlen);
yystate(19, Ics, Line, Tlen, _, _) ->
    {10,Tlen,Ics,Line,19};
yystate(18, [114|Ics], Line, Tlen, _, _) ->
    yystate(18, Ics, Line, Tlen+1, 5, Tlen);
yystate(18, Ics, Line, Tlen, _, _) ->
    {5,Tlen,Ics,Line,18};
yystate(17, [79|Ics], Line, Tlen, _, _) ->
    yystate(17, Ics, Line, Tlen+1, 32, Tlen);
yystate(17, Ics, Line, Tlen, _, _) ->
    {32,Tlen,Ics,Line,17};
yystate(16, [113|Ics], Line, Tlen, _, _) ->
    yystate(16, Ics, Line, Tlen+1, 6, Tlen);
yystate(16, Ics, Line, Tlen, _, _) ->
    {6,Tlen,Ics,Line,16};
yystate(15, [81|Ics], Line, Tlen, _, _) ->
    yystate(15, Ics, Line, Tlen+1, 7, Tlen);
yystate(15, Ics, Line, Tlen, _, _) ->
    {7,Tlen,Ics,Line,15};
yystate(14, [109|Ics], Line, Tlen, _, _) ->
    yystate(14, Ics, Line, Tlen+1, 27, Tlen);
yystate(14, Ics, Line, Tlen, _, _) ->
    {27,Tlen,Ics,Line,14};
yystate(13, [83|Ics], Line, Tlen, _, _) ->
    yystate(13, Ics, Line, Tlen+1, 29, Tlen);
yystate(13, Ics, Line, Tlen, _, _) ->
    {29,Tlen,Ics,Line,13};
yystate(12, [107|Ics], Line, Tlen, _, _) ->
    yystate(12, Ics, Line, Tlen+1, 25, Tlen);
yystate(12, Ics, Line, Tlen, _, _) ->
    {25,Tlen,Ics,Line,12};
yystate(11, [85|Ics], Line, Tlen, _, _) ->
    yystate(11, Ics, Line, Tlen+1, 4, Tlen);
yystate(11, Ics, Line, Tlen, _, _) ->
    {4,Tlen,Ics,Line,11};
yystate(10, [104|Ics], Line, Tlen, _, _) ->
    yystate(10, Ics, Line, Tlen+1, 23, Tlen);
yystate(10, Ics, Line, Tlen, _, _) ->
    {23,Tlen,Ics,Line,10};
yystate(9, [86|Ics], Line, Tlen, _, _) ->
    yystate(9, Ics, Line, Tlen+1, 34, Tlen);
yystate(9, Ics, Line, Tlen, _, _) ->
    {34,Tlen,Ics,Line,9};
yystate(8, [101|Ics], Line, Tlen, _, _) ->
    yystate(8, Ics, Line, Tlen+1, 18, Tlen);
yystate(8, Ics, Line, Tlen, _, _) ->
    {18,Tlen,Ics,Line,8};
yystate(7, [87|Ics], Line, Tlen, _, _) ->
    yystate(7, Ics, Line, Tlen+1, 13, Tlen);
yystate(7, Ics, Line, Tlen, _, _) ->
    {13,Tlen,Ics,Line,7};
yystate(6, [100|Ics], Line, Tlen, _, _) ->
    yystate(6, Ics, Line, Tlen+1, 14, Tlen);
yystate(6, Ics, Line, Tlen, _, _) ->
    {14,Tlen,Ics,Line,6};
yystate(5, [88|Ics], Line, Tlen, _, _) ->
    yystate(5, Ics, Line, Tlen+1, 35, Tlen);
yystate(5, Ics, Line, Tlen, _, _) ->
    {35,Tlen,Ics,Line,5};
yystate(4, [99|Ics], Line, Tlen, _, _) ->
    yystate(4, Ics, Line, Tlen+1, 19, Tlen);
yystate(4, Ics, Line, Tlen, _, _) ->
    {19,Tlen,Ics,Line,4};
yystate(3, [89|Ics], Line, Tlen, _, _) ->
    yystate(3, Ics, Line, Tlen+1, 2, Tlen);
yystate(3, Ics, Line, Tlen, _, _) ->
    {2,Tlen,Ics,Line,3};
yystate(2, [98|Ics], Line, Tlen, _, _) ->
    yystate(2, Ics, Line, Tlen+1, 21, Tlen);
yystate(2, Ics, Line, Tlen, _, _) ->
    {21,Tlen,Ics,Line,2};
yystate(1, [90|Ics], Line, Tlen, _, _) ->
    yystate(1, Ics, Line, Tlen+1, 31, Tlen);
yystate(1, Ics, Line, Tlen, _, _) ->
    {31,Tlen,Ics,Line,1};
yystate(0, [97|Ics], Line, Tlen, _, _) ->
    yystate(0, Ics, Line, Tlen+1, 20, Tlen);
yystate(0, Ics, Line, Tlen, _, _) ->
    {20,Tlen,Ics,Line,0};
yystate(S, Ics, Line, Tlen, Action, Alen) ->
    {Action,Alen,Tlen,Ics,Line,S}.

%% yyaction(Action, TokenLength, TokenChars, TokenLine) ->
%% {token,Token} | {end_token, Token} | skip_token | {error,String}.
%% Generated action function.

yyaction(0, TokenLen, YYtcs, TokenLine) ->
    TokenChars = yypre(YYtcs, TokenLen),
    yyaction_0(TokenChars, TokenLine);
yyaction(1, TokenLen, YYtcs, TokenLine) ->
    TokenChars = yypre(YYtcs, TokenLen),
    yyaction_1(TokenChars, TokenLine);
yyaction(2, TokenLen, YYtcs, TokenLine) ->
    TokenChars = yypre(YYtcs, TokenLen),
    yyaction_2(TokenChars, TokenLine);
yyaction(3, TokenLen, YYtcs, TokenLine) ->
    TokenChars = yypre(YYtcs, TokenLen),
    yyaction_3(TokenChars, TokenLine);
yyaction(4, TokenLen, YYtcs, TokenLine) ->
    TokenChars = yypre(YYtcs, TokenLen),
    yyaction_4(TokenChars, TokenLine);
yyaction(5, TokenLen, YYtcs, TokenLine) ->
    TokenChars = yypre(YYtcs, TokenLen),
    yyaction_5(TokenChars, TokenLine);
yyaction(6, TokenLen, YYtcs, TokenLine) ->
    TokenChars = yypre(YYtcs, TokenLen),
    yyaction_6(TokenChars, TokenLine);
yyaction(7, TokenLen, YYtcs, TokenLine) ->
    TokenChars = yypre(YYtcs, TokenLen),
    yyaction_7(TokenChars, TokenLine);
yyaction(8, _, _, TokenLine) ->
    yyaction_8(TokenLine);
yyaction(9, _, _, TokenLine) ->
    yyaction_9(TokenLine);
yyaction(10, TokenLen, YYtcs, TokenLine) ->
    TokenChars = yypre(YYtcs, TokenLen),
    yyaction_10(TokenChars, TokenLine);
yyaction(11, TokenLen, YYtcs, TokenLine) ->
    TokenChars = yypre(YYtcs, TokenLen),
    yyaction_11(TokenChars, TokenLine);
yyaction(12, TokenLen, YYtcs, TokenLine) ->
    TokenChars = yypre(YYtcs, TokenLen),
    yyaction_12(TokenChars, TokenLine);
yyaction(13, TokenLen, YYtcs, TokenLine) ->
    TokenChars = yypre(YYtcs, TokenLen),
    yyaction_13(TokenChars, TokenLine);
yyaction(14, TokenLen, YYtcs, TokenLine) ->
    TokenChars = yypre(YYtcs, TokenLen),
    yyaction_14(TokenChars, TokenLine);
yyaction(15, TokenLen, YYtcs, TokenLine) ->
    TokenChars = yypre(YYtcs, TokenLen),
    yyaction_15(TokenChars, TokenLine);
yyaction(16, TokenLen, YYtcs, TokenLine) ->
    TokenChars = yypre(YYtcs, TokenLen),
    yyaction_16(TokenChars, TokenLine);
yyaction(17, TokenLen, YYtcs, TokenLine) ->
    TokenChars = yypre(YYtcs, TokenLen),
    yyaction_17(TokenChars, TokenLine);
yyaction(18, TokenLen, YYtcs, TokenLine) ->
    TokenChars = yypre(YYtcs, TokenLen),
    yyaction_18(TokenChars, TokenLine);
yyaction(19, TokenLen, YYtcs, TokenLine) ->
    TokenChars = yypre(YYtcs, TokenLen),
    yyaction_19(TokenChars, TokenLine);
yyaction(20, TokenLen, YYtcs, TokenLine) ->
    TokenChars = yypre(YYtcs, TokenLen),
    yyaction_20(TokenChars, TokenLine);
yyaction(21, TokenLen, YYtcs, TokenLine) ->
    TokenChars = yypre(YYtcs, TokenLen),
    yyaction_21(TokenChars, TokenLine);
yyaction(22, TokenLen, YYtcs, TokenLine) ->
    TokenChars = yypre(YYtcs, TokenLen),
    yyaction_22(TokenChars, TokenLine);
yyaction(23, TokenLen, YYtcs, TokenLine) ->
    TokenChars = yypre(YYtcs, TokenLen),
    yyaction_23(TokenChars, TokenLine);
yyaction(24, TokenLen, YYtcs, TokenLine) ->
    TokenChars = yypre(YYtcs, TokenLen),
    yyaction_24(TokenChars, TokenLine);
yyaction(25, TokenLen, YYtcs, TokenLine) ->
    TokenChars = yypre(YYtcs, TokenLen),
    yyaction_25(TokenChars, TokenLine);
yyaction(26, TokenLen, YYtcs, TokenLine) ->
    TokenChars = yypre(YYtcs, TokenLen),
    yyaction_26(TokenChars, TokenLine);
yyaction(27, TokenLen, YYtcs, TokenLine) ->
    TokenChars = yypre(YYtcs, TokenLen),
    yyaction_27(TokenChars, TokenLine);
yyaction(28, TokenLen, YYtcs, TokenLine) ->
    TokenChars = yypre(YYtcs, TokenLen),
    yyaction_28(TokenChars, TokenLine);
yyaction(29, TokenLen, YYtcs, TokenLine) ->
    TokenChars = yypre(YYtcs, TokenLen),
    yyaction_29(TokenChars, TokenLine);
yyaction(30, TokenLen, YYtcs, TokenLine) ->
    TokenChars = yypre(YYtcs, TokenLen),
    yyaction_30(TokenChars, TokenLine);
yyaction(31, TokenLen, YYtcs, TokenLine) ->
    TokenChars = yypre(YYtcs, TokenLen),
    yyaction_31(TokenChars, TokenLine);
yyaction(32, TokenLen, YYtcs, TokenLine) ->
    TokenChars = yypre(YYtcs, TokenLen),
    yyaction_32(TokenChars, TokenLine);
yyaction(33, TokenLen, YYtcs, TokenLine) ->
    TokenChars = yypre(YYtcs, TokenLen),
    yyaction_33(TokenChars, TokenLine);
yyaction(34, TokenLen, YYtcs, TokenLine) ->
    TokenChars = yypre(YYtcs, TokenLen),
    yyaction_34(TokenChars, TokenLine);
yyaction(35, TokenLen, YYtcs, TokenLine) ->
    TokenChars = yypre(YYtcs, TokenLen),
    yyaction_35(TokenChars, TokenLine);
yyaction(36, TokenLen, YYtcs, TokenLine) ->
    TokenChars = yypre(YYtcs, TokenLen),
    yyaction_36(TokenChars, TokenLine);
yyaction(37, TokenLen, YYtcs, TokenLine) ->
    TokenChars = yypre(YYtcs, TokenLen),
    yyaction_37(TokenChars, TokenLine);
yyaction(38, _, _, TokenLine) ->
    yyaction_38(TokenLine);
yyaction(39, TokenLen, YYtcs, TokenLine) ->
    TokenChars = yypre(YYtcs, TokenLen),
    yyaction_39(TokenChars, TokenLine);
yyaction(_, _, _, _) -> error.

-compile({inline,yyaction_0/2}).
-file("src/datetime_format_lexer.xrl", 60).
yyaction_0(TokenChars, TokenLine) ->
     { token, { era, TokenLine, count (TokenChars) } } .

-compile({inline,yyaction_1/2}).
-file("src/datetime_format_lexer.xrl", 62).
yyaction_1(TokenChars, TokenLine) ->
     { token, { year, TokenLine, count (TokenChars) } } .

-compile({inline,yyaction_2/2}).
-file("src/datetime_format_lexer.xrl", 63).
yyaction_2(TokenChars, TokenLine) ->
     { token, { week_aligned_year, TokenLine, count (TokenChars) } } .

-compile({inline,yyaction_3/2}).
-file("src/datetime_format_lexer.xrl", 64).
yyaction_3(TokenChars, TokenLine) ->
     { token, { extended_year, TokenLine, count (TokenChars) } } .

-compile({inline,yyaction_4/2}).
-file("src/datetime_format_lexer.xrl", 65).
yyaction_4(TokenChars, TokenLine) ->
     { token, { cyclic_year, TokenLine, count (TokenChars) } } .

-compile({inline,yyaction_5/2}).
-file("src/datetime_format_lexer.xrl", 66).
yyaction_5(TokenChars, TokenLine) ->
     { token, { related_year, TokenLine, count (TokenChars) } } .

-compile({inline,yyaction_6/2}).
-file("src/datetime_format_lexer.xrl", 68).
yyaction_6(TokenChars, TokenLine) ->
     { token, { quarter, TokenLine, count (TokenChars) } } .

-compile({inline,yyaction_7/2}).
-file("src/datetime_format_lexer.xrl", 69).
yyaction_7(TokenChars, TokenLine) ->
     { token, { standalone_quarter, TokenLine, count (TokenChars) } } .

-compile({inline,yyaction_8/1}).
-file("src/datetime_format_lexer.xrl", 71).
yyaction_8(TokenLine) ->
     { token, { time, TokenLine, 0 } } .

-compile({inline,yyaction_9/1}).
-file("src/datetime_format_lexer.xrl", 72).
yyaction_9(TokenLine) ->
     { token, { date, TokenLine, 0 } } .

-compile({inline,yyaction_10/2}).
-file("src/datetime_format_lexer.xrl", 74).
yyaction_10(TokenChars, TokenLine) ->
     { token, { month, TokenLine, count (TokenChars) } } .

-compile({inline,yyaction_11/2}).
-file("src/datetime_format_lexer.xrl", 75).
yyaction_11(TokenChars, TokenLine) ->
     { token, { standalone_month, TokenLine, count (TokenChars) } } .

-compile({inline,yyaction_12/2}).
-file("src/datetime_format_lexer.xrl", 77).
yyaction_12(TokenChars, TokenLine) ->
     { token, { week_of_year, TokenLine, count (TokenChars) } } .

-compile({inline,yyaction_13/2}).
-file("src/datetime_format_lexer.xrl", 78).
yyaction_13(TokenChars, TokenLine) ->
     { token, { week_of_month, TokenLine, count (TokenChars) } } .

-compile({inline,yyaction_14/2}).
-file("src/datetime_format_lexer.xrl", 79).
yyaction_14(TokenChars, TokenLine) ->
     { token, { day_of_month, TokenLine, count (TokenChars) } } .

-compile({inline,yyaction_15/2}).
-file("src/datetime_format_lexer.xrl", 80).
yyaction_15(TokenChars, TokenLine) ->
     { token, { day_of_year, TokenLine, count (TokenChars) } } .

-compile({inline,yyaction_16/2}).
-file("src/datetime_format_lexer.xrl", 81).
yyaction_16(TokenChars, TokenLine) ->
     { token, { day_of_week_in_month, TokenLine, count (TokenChars) } } .

-compile({inline,yyaction_17/2}).
-file("src/datetime_format_lexer.xrl", 83).
yyaction_17(TokenChars, TokenLine) ->
     { token, { day_name, TokenLine, count (TokenChars) } } .

-compile({inline,yyaction_18/2}).
-file("src/datetime_format_lexer.xrl", 84).
yyaction_18(TokenChars, TokenLine) ->
     { token, { day_of_week, TokenLine, count (TokenChars) } } .

-compile({inline,yyaction_19/2}).
-file("src/datetime_format_lexer.xrl", 85).
yyaction_19(TokenChars, TokenLine) ->
     { token, { standalone_day_of_week, TokenLine, count (TokenChars) } } .

-compile({inline,yyaction_20/2}).
-file("src/datetime_format_lexer.xrl", 87).
yyaction_20(TokenChars, TokenLine) ->
     { token, { period_am_pm, TokenLine, count (TokenChars) } } .

-compile({inline,yyaction_21/2}).
-file("src/datetime_format_lexer.xrl", 88).
yyaction_21(TokenChars, TokenLine) ->
     { token, { period_noon_mid, TokenLine, count (TokenChars) } } .

-compile({inline,yyaction_22/2}).
-file("src/datetime_format_lexer.xrl", 89).
yyaction_22(TokenChars, TokenLine) ->
     { token, { period_flex, TokenLine, count (TokenChars) } } .

-compile({inline,yyaction_23/2}).
-file("src/datetime_format_lexer.xrl", 91).
yyaction_23(TokenChars, TokenLine) ->
     { token, { hour_1_12, TokenLine, count (TokenChars) } } .

-compile({inline,yyaction_24/2}).
-file("src/datetime_format_lexer.xrl", 92).
yyaction_24(TokenChars, TokenLine) ->
     { token, { hour_0_11, TokenLine, count (TokenChars) } } .

-compile({inline,yyaction_25/2}).
-file("src/datetime_format_lexer.xrl", 93).
yyaction_25(TokenChars, TokenLine) ->
     { token, { hour_1_24, TokenLine, count (TokenChars) } } .

-compile({inline,yyaction_26/2}).
-file("src/datetime_format_lexer.xrl", 94).
yyaction_26(TokenChars, TokenLine) ->
     { token, { hour_0_23, TokenLine, count (TokenChars) } } .

-compile({inline,yyaction_27/2}).
-file("src/datetime_format_lexer.xrl", 96).
yyaction_27(TokenChars, TokenLine) ->
     { token, { minute, TokenLine, count (TokenChars) } } .

-compile({inline,yyaction_28/2}).
-file("src/datetime_format_lexer.xrl", 97).
yyaction_28(TokenChars, TokenLine) ->
     { token, { second, TokenLine, count (TokenChars) } } .

-compile({inline,yyaction_29/2}).
-file("src/datetime_format_lexer.xrl", 98).
yyaction_29(TokenChars, TokenLine) ->
     { token, { fractional_second, TokenLine, count (TokenChars) } } .

-compile({inline,yyaction_30/2}).
-file("src/datetime_format_lexer.xrl", 100).
yyaction_30(TokenChars, TokenLine) ->
     { token, { zone_short, TokenLine, count (TokenChars) } } .

-compile({inline,yyaction_31/2}).
-file("src/datetime_format_lexer.xrl", 101).
yyaction_31(TokenChars, TokenLine) ->
     { token, { zone_basic, TokenLine, count (TokenChars) } } .

-compile({inline,yyaction_32/2}).
-file("src/datetime_format_lexer.xrl", 102).
yyaction_32(TokenChars, TokenLine) ->
     { token, { zone_gmt, TokenLine, count (TokenChars) } } .

-compile({inline,yyaction_33/2}).
-file("src/datetime_format_lexer.xrl", 103).
yyaction_33(TokenChars, TokenLine) ->
     { token, { zone_generic, TokenLine, count (TokenChars) } } .

-compile({inline,yyaction_34/2}).
-file("src/datetime_format_lexer.xrl", 104).
yyaction_34(TokenChars, TokenLine) ->
     { token, { zone_id, TokenLine, count (TokenChars) } } .

-compile({inline,yyaction_35/2}).
-file("src/datetime_format_lexer.xrl", 105).
yyaction_35(TokenChars, TokenLine) ->
     { token, { zone_iso_z, TokenLine, count (TokenChars) } } .

-compile({inline,yyaction_36/2}).
-file("src/datetime_format_lexer.xrl", 106).
yyaction_36(TokenChars, TokenLine) ->
     { token, { zone_iso, TokenLine, count (TokenChars) } } .

-compile({inline,yyaction_37/2}).
-file("src/datetime_format_lexer.xrl", 108).
yyaction_37(TokenChars, TokenLine) ->
     { token, { literal, TokenLine, 'Elixir.List' : to_string (unquote (TokenChars)) } } .

-compile({inline,yyaction_38/1}).
-file("src/datetime_format_lexer.xrl", 109).
yyaction_38(TokenLine) ->
     { token, { literal, TokenLine, << "'" >> } } .

-compile({inline,yyaction_39/2}).
-file("src/datetime_format_lexer.xrl", 110).
yyaction_39(TokenChars, TokenLine) ->
     { token, { literal, TokenLine, 'Elixir.List' : to_string (TokenChars) } } .

-file("/usr/local/Cellar/erlang/20.0/lib/erlang/lib/parsetools-2.1.5/include/leexinc.hrl", 309).
