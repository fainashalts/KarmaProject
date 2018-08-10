pragma solidity ^0.4.18;

contract Fundraiser {
	mapping(address => uint) private balances;
	address public creator;
	address fundraiserRecipient;
	uint public fundingGoal;
	string fundraiserUrl;
	//version #
	uint constant version = 1;
	uint storedData;
	//Data structures for fundraising
	enum fundraiserState {
		InProgress, 
		CompletedSuccess,
		CompletedFailure,
		Closed
	}

	// donation details; will be used for tallying donations, as well as contribution point processing
	struct Donation {
		uint amount;
		address donator;
	}

	//State variables
	//initialize first state for fundraiser on create
	fundraiserState public state = fundraiserState.InProgress;
	uint public totalRaised;
	uint public currentBalance;
	uint public fundraiserDeadline;
	uint public completeAt;

	Donation[] donations;

	//events
	event LogDonationReceived(address addr, uint amount, uint currentTotal);
	event LogFundraiserPaid(address fundraiserAddress);
	event LogFundraiserInitialized(
		address creator,
		address fundraiserRecipient,
		string url,
		uint _fundingGoal,
		uint256 fundraiserDeadline
	);

	// modifier to ensure that fundraiser is in one of the possible states; revert if not
	modifier inState(fundraiserState _state) {
		if (state != _state) revert();
		_;
	}

	//modifier to ensure that the creator is the msg.sender
	modifier isCreator() {
		if(msg.sender != creator) revert();
		_;
	}

	constructor() public {
		
	}

	//function to initialize fundraiser
	function initFundraiser (uint timeForFundraising, string _fundraiserUrl, address _fundraiserRecipient, uint _fundingGoal) public {
		creator = msg.sender;
		fundraiserRecipient =  _fundraiserRecipient;
		fundraiserUrl = _fundraiserUrl;
		//convert to wei
		fundingGoal = _fundingGoal * 1000000000000000000;	
		timeForFundraising = now + (timeForFundraising * 1 hours);
		currentBalance = 0;
		emit LogFundraiserInitialized(creator, fundraiserRecipient, fundraiserUrl, fundingGoal, timeForFundraising);
	}

	function set(uint x) public {
    	storedData = x;
  	}

  	function get() public view returns (uint) {
    	return storedData;
  	}
	function Donate()
	public
	inState(fundraiserState.InProgress) payable returns (uint256)
	{
		donations.push(Donation({
			amount: msg.value,
			donator: msg.sender 	
		}));
		totalRaised += msg.value;
		currentBalance = totalRaised;
		emit LogDonationReceived(msg.sender, msg.value, totalRaised);
		//need something here to check whether fundraiser has reached its goal or expired
		//need donation id, which is the index in the array
		return donations.length - 1;
	}

	function payOut()
	public
	inState(fundraiserState.CompletedSuccess)
	{
		if(!creator.send(balances[creator])) {
			revert();
		}
		if(!fundraiserRecipient.send(balances[creator])) {
			revert();
		}
		state = fundraiserState.Closed;
		currentBalance = 0;
		emit LogFundraiserPaid(creator);
	}

	function getRefund(uint256 id)
	public
	inState(fundraiserState.CompletedFailure)
	returns (bool)
	{
		if(donations.length <= id || id < 0 || donations[id].amount == 0) {
			revert();
		}
		uint amountToRefund = donations[id].amount;
		donations[id].amount = 0;

		if(!donations[id].donator.send(amountToRefund))
		{
			donations[id].amount = amountToRefund;
			return false;
		}
		else{
			totalRaised = amountToRefund;
			currentBalance = totalRaised;
		}
		return true;
	}

	function removeContract()
	public
	isCreator()
	// end of fundraiser handling once that function is written
	{
		selfdestruct(msg.sender);
		// creator will get any money left in the contract
	}

	//default function
	function() public {
		revert();
	}

}
