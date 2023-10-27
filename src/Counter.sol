//license:
pragma solidity ^0.8.0;

contract CardsAgainstHumanity {
    enum GameState {
        LOBBY,
        PROMPT,
        REVEAL
    }

    struct Player {
        address payable playerAddress;
        string answer;
        bool hasAnswered;
    }

    struct Game {
        GameState state;
        address payable judge;
        uint256 judgeStake;
        string prompt;
        Player[] players;
        mapping(address => bool) hasSubmitted;
    }

    uint256 public currentGameId = 0;
    mapping(uint256 => Game) public games;

    // Events
    event NewGame(uint256 gameId, address judge, string prompt);
    event PlayerJoined(uint256 gameId, address player);
    event GameAdvanced(uint256 gameId, GameState newState);
    event WinnerDeclared(uint256 gameId, address winner);

    // Start a new game with a random prompt
    function startGame() external payable {
        require(msg.value == 0.1 ether, "Must stake 0.1 ether to be judge.");
        uint256 gameId = ++currentGameId;
        string memory prompt = _getRandomPrompt();
        games[gameId] = Game({
            state: GameState.LOBBY,
            judge: payable(msg.sender),
            judgeStake: msg.value,
            prompt: prompt,
            players: new Player[](0)
        });
        emit NewGame(gameId, msg.sender, prompt);
    }

    // Players join and submit their answers
    function submitAnswer(
        uint256 gameId,
        string memory answer
    ) external payable {
        require(msg.value == 0.01 ether, "Must bet 0.01 ether to play.");
        Game storage game = games[gameId];
        require(
            game.state == GameState.LOBBY,
            "Game is not in the right state."
        );
        require(
            !game.hasSubmitted[msg.sender],
            "You have already submitted an answer."
        );

        game.players.push(
            Player({
                playerAddress: payable(msg.sender),
                answer: answer,
                hasAnswered: true
            })
        );
        game.hasSubmitted[msg.sender] = true;

        emit PlayerJoined(gameId, msg.sender);
    }

    // Advance game states
    function advanceState(uint256 gameId) external {
        Game storage game = games[gameId];
        require(msg.sender == game.judge, "Only judge can advance the game.");

        if (game.state == GameState.LOBBY) {
            game.state = GameState.PROMPT;
        } else if (game.state == GameState.PROMPT) {
            game.state = GameState.REVEAL;
        }

        emit GameAdvanced(gameId, game.state);
    }

    // Judge declares the winner
    function declareWinner(uint256 gameId, address winner) external {
        Game storage game = games[gameId];
        require(msg.sender == game.judge, "Only judge can declare a winner.");
        require(
            game.state == GameState.REVEAL,
            "Game is not in the reveal state."
        );

        uint256 totalPot = address(this).balance;
        payable(winner).transfer(totalPot);

        emit WinnerDeclared(gameId, winner);
    }

    function _getRandomPrompt() internal pure returns (string memory) {
        // Simplified. In a real scenario, you'd need off-chain randomness.
        uint256 rand = block.timestamp % 4;
        if (rand == 0) return "She’s a 10, but _________";
        if (rand == 1) return "My Roman Empire is ______";
        if (rand == 2)
            return
                "This combo would have taken a whole city out in the 1500s: ______";
        return "The secret to _______ is _______";
    }
}
