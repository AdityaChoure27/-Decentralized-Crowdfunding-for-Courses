// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CourseCrowdfunding {
    address public courseCreator;
    uint public fundingGoal;
    uint public deadline;
    uint public totalFunds;
    bool public courseFunded;
    mapping(address => uint) public contributions;
    address[] public contributors;

    // Events to emit when contributions are made or refunded
    event ContributionReceived(address contributor, uint amount);
    event RefundIssued(address contributor, uint amount);
    event GoalReached(address creator, uint totalFunds);

    // Modifier to restrict actions to the course creator
    modifier onlyCreator() {
        require(msg.sender == courseCreator, "Only the course creator can perform this action");
        _;
    }

    // Modifier to check if the crowdfunding period is still active
    modifier beforeDeadline() {
        require(block.timestamp < deadline, "Crowdfunding period has ended");
        _;
    }

    // Modifier to check if the crowdfunding goal is reached
    modifier afterDeadline() {
        require(block.timestamp >= deadline, "Crowdfunding period has not ended yet");
        _;
    }

    // Constructor to initialize the contract with course creator address, funding goal and deadline
    constructor(uint _fundingGoal, uint _durationInDays) {
        courseCreator = msg.sender;
        fundingGoal = _fundingGoal;
        deadline = block.timestamp + _durationInDays * 1 days;
        totalFunds = 0;
        courseFunded = false;
    }

    // Function for contributors to fund the course
    function contribute() public payable beforeDeadline {
        require(msg.value > 0, "Contribution must be greater than zero");
        
        if (contributions[msg.sender] == 0) {
            contributors.push(msg.sender);  // Add contributor to list
        }

        contributions[msg.sender] += msg.value;
        totalFunds += msg.value;

        emit ContributionReceived(msg.sender, msg.value);

        // Check if the funding goal is met
        if (totalFunds >= fundingGoal && !courseFunded) {
            courseFunded = true;
            emit GoalReached(courseCreator, totalFunds);
        }
    }

    // Function to refund contributors if goal is not met
    function refund() public afterDeadline {
        require(totalFunds < fundingGoal, "Funding goal was reached, no refund needed");
        
        uint contributedAmount = contributions[msg.sender];
        require(contributedAmount > 0, "You have not contributed");

        contributions[msg.sender] = 0;
        totalFunds -= contributedAmount;

        payable(msg.sender).transfer(contributedAmount);
        emit RefundIssued(msg.sender, contributedAmount);
    }

    // Function to release funds to the course creator if the funding goal is met
    function releaseFunds() public onlyCreator afterDeadline {
        require(courseFunded, "Funding goal was not reached");
        require(address(this).balance >= totalFunds, "Insufficient contract balance");

        payable(courseCreator).transfer(address(this).balance);
    }

    // Function to view all contributors (for transparency)
    function getContributors() public view returns (address[] memory) {
        return contributors;
    }

    // Function to view current contract balance
    function getContractBalance() public view returns (uint) {
        return address(this).balance;
    }
}
