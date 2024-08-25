// SPDX-License-Identifier: MIT
pragma  solidity ^0.8.0;

contract BlockchainISA {
    uint public isaId;

    struct ISA {
        address student;
        uint fundedAmount;
        uint repaymentPercentage;
        uint incomeThreshold;
        uint duration;
        uint startTime;
        uint totalRepaid;
        bool isActive;
    }

    mapping(uint => ISA) public isas;
    mapping(uint => mapping(address => uint)) public funders;
    mapping(uint => uint) public totalFunded;
    mapping(uint => uint) public totalRepaid;

    constructor() {
        isaId = 0;
    }

    function createISA(uint _fundedAmount, uint _repaymentPercentage, uint _incomeThreshold, uint _duration) public {
        isaId++;
        ISA storage newISA = isas[isaId];
        newISA.student = msg.sender;
        newISA.fundedAmount = _fundedAmount;
        newISA.repaymentPercentage = _repaymentPercentage;
        newISA.incomeThreshold = _incomeThreshold;
        newISA.duration = _duration;
        newISA.startTime = block.timestamp;
        newISA.isActive = true;
    }

    function fundISA(uint _isaId, uint _fundingAmount) public payable {
        require(isas[_isaId].isActive, "ISA is not active");
        require(_fundingAmount > 0, "Funding amount must be greater than 0");
        require(msg.value == _fundingAmount, "Funding amount mismatch");

        funders[_isaId][msg.sender] += _fundingAmount;
        totalFunded[_isaId] += _fundingAmount;
    }


    function reportIncome(uint _isaId, uint _income) public {
        ISA storage isa = isas[_isaId];
        require(msg.sender == isa.student, "Only the student can report income");
        require(block.timestamp < isa.startTime + isa.duration, "ISA duration has ended");

        if (_income >= isa.incomeThreshold) {
            uint repaymentAmount = (_income * isa.repaymentPercentage) / 100;
            totalRepaid[_isaId] += repaymentAmount;
            payable(isa.student).transfer(repaymentAmount);
        }
    }

    function finalizeISA(uint _isaId) public {
        ISA storage isa = isas[_isaId];
        require(msg.sender == isa.student || msg.sender == address(this), "Only the student or contract can finalize");

        if (block.timestamp >= isa.startTime + isa.duration || totalRepaid[_isaId] >= isa.fundedAmount) {
            isa.isActive = false;
        }
    }

    function requestRefund(uint _isaId) public {
        ISA storage isa = isas[_isaId];
        require(block.timestamp >= isa.startTime + isa.duration, "ISA duration not ended");
        require(totalRepaid[_isaId] < isa.fundedAmount, "No refund available");

        uint refundAmount = isa.fundedAmount - totalRepaid[_isaId];
        payable(isa.student).transfer(refundAmount);
    }
}
