pragma solidity ^0.6.0;
import "../utils/access.sol";

  contract StateMachine is Access{
    
    struct rule{
        bool exists;
        string nextState;
    }
    
 
    event TransitionCreated(string originState, bytes32 functionhash, string targetState);
    event CurrentState(bytes32 state);

    

    mapping (string => mapping(bytes32 => rule)) internal _transitions;

  
    constructor(address _a)
        public
    {
        access = PermissionControl(_a);
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
    function createTransition (string memory originState, bytes32 functionhash, string memory targetState) public 
    {
        require(_isAdmin(msg.sender),"T01");
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
