pragma solidity ^0.6.0;
//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
/**
 * @title StateMachine
 * @author Alberto Cuesta Canada
 * @dev Implements a simple state machine:
 *  - All states exist by default.
 *  - No transitions exist by default.
 *  - The state machine starts at "SETUP".
 *  - New transitions can be created while in the "SETUP state".
 */
 

 
contract StateMachine is Ownable{
    
    struct rule{
        bool exists;
        string nextState;
    }
 
 
    event TransitionCreated(string originState, bytes32 functionhash, string targetState);
    event CurrentState(bytes32 state);

 

    mapping (string => mapping(bytes32 => rule)) internal _transitions;

  
    constructor()
        public
    {
      
    }


    function transitionExists(string memory originState, bytes32 functionhash)
        public
        virtual
        view
        returns(bool,string memory)
    {
        return (_transitions[originState][functionhash].exists, _transitions[originState][functionhash].nextState);
    }

    /**
     * @dev Create a transition between two states.
     */
    function createTransition (string memory originState, bytes32 functionhash, string memory targetState)
       public  onlyOwner
    {
        (bool exist, ) = transitionExists(originState, functionhash);
        require(
            (!exist) ,
            "Transition already exists."
        );

        _transitions[originState][functionhash].exists=true;
        _transitions[originState][functionhash].nextState=targetState;
        emit TransitionCreated(originState, functionhash , targetState);
    }
    
}
