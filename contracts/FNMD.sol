// Copyright 2018, Oath Inc
// Licensed under the terms of the MIT license. See LICENSE file in License.md for terms.

pragma solidity ^0.4.14;

import './Ownable.sol';

contract FNMD is Ownable {
    struct Participant {
        address id;
        int reputation;
    }
    
    struct Validator {
        address id;
        int rate;
    }

    struct Article {
        string title;
        string content;
        uint date;
        address author;
        uint deposit;
        uint reward;
        Validator[] validators;
        uint positiveRate;
        uint negativeRate;
        int validatorScore;
        int score;
        bool rewarded;
    }
    
    uint constant WITHHOLD_PERIOD = 1 days;
    uint constant PANALTY_PERIOD = 1 days;
    uint constant GRAVITY = 2;
    uint constant PARTICIPATE_FEE = 1 ether;
    uint constant AUTHOR_REWARD_PERCENT = 50;
    uint constant RATEFEE = 1 finney;
    int constant BASE_REPUTATION = 1 finney;

    mapping(address => Participant) public participants;
    mapping(uint => Article) public articles;
    uint articleCount;
    
    modifier participantExit() {
        assert(participants[msg.sender].id != 0x0);
        _;
    }
    
    modifier articleExit(uint id) {
        assert(id < articleCount);
        _;
    }
    
    modifier participantNotExit() {
        assert(participants[msg.sender].id == 0x0);
        _;
    }
    
    function _calculateScore(Article storage article) private {
        Validator[] memory validators = article.validators;
        int publisherScore = participants[article.author].reputation + int(article.deposit);
        int validatorScore = article.validatorScore;
        
        if (validators.length > 0) {
            validatorScore /= int(validators.length);
        }
        
        uint timePanalty = ((now - article.date) / PANALTY_PERIOD + PANALTY_PERIOD) ** GRAVITY;
        int score = (publisherScore + int(article.reward) + validatorScore) / int(timePanalty);
        article.score = score;
    }
    
    function _calculateValidatorScore(Article storage article) private {
        Validator[] memory validators = article.validators;
        int validatorScore = article.validatorScore;
        Validator memory newValidator = validators[validators.length - 1];
        validatorScore += newValidator.rate * participants[newValidator.id].reputation;
        article.validatorScore = validatorScore;
    }
    
    function _rewardPositive(Article storage article) private {
        Validator[] memory validators = article.validators;
        uint negativeFee = article.negativeRate * RATEFEE;
        uint totalReward = article.reward + negativeFee;
        uint authorReward = totalReward * AUTHOR_REWARD_PERCENT / 100;
        uint validatorReward = (totalReward - authorReward) / article.positiveRate;
        
        article.author.transfer(authorReward + article.deposit);
        participants[article.author].reputation += BASE_REPUTATION;
        
        for (uint i = 0; i < validators.length; i++) {
            Validator memory validator = validators[i];
            if (validator.rate > 0) {
                uint absRate = uint(validator.rate);
                validator.id.transfer(absRate * (validatorReward + RATEFEE));
                participants[validator.id].reputation += BASE_REPUTATION;
            } else {
                participants[validator.id].reputation -= BASE_REPUTATION;
            }
        }
    }

    function _rewardNegative(Article storage article) private {
        Validator[] memory validators = article.validators;
        uint positiveFee = article.positiveRate * RATEFEE;
        uint totalReward = article.reward + positiveFee + article.deposit;
        uint validatorReward = totalReward / article.negativeRate;
        
        participants[article.author].reputation -= BASE_REPUTATION; 
        
        for (uint i = 0; i < validators.length; i++) {
            Validator memory validator = validators[i];
            if (validator.rate < 0) {
                uint absRate = uint(-1 * validator.rate);
                validator.id.transfer(absRate * (validatorReward + RATEFEE));
                participants[validator.id].reputation += BASE_REPUTATION;
            } else {
                participants[validator.id].reputation -= BASE_REPUTATION;
            }
        }
    }

    function participate() participantNotExit public payable {
      require(msg.value == 0 || msg.value == PARTICIPATE_FEE);

      int reputation = BASE_REPUTATION + int(msg.value);
      participants[msg.sender] = Participant(msg.sender, reputation);
    }

    function publish(string title, string content) participantExit public payable {        
        Article storage article = articles[articleCount];
        article.title = title;
        article.content = content;
        article.date = now;
        article.author = msg.sender;
        article.deposit = msg.value;
        _calculateScore(article);
        articleCount += 1;
    }
    
    function validate(uint id, int rate) participantExit articleExit(id) public payable {
        require(rate != 0);
        Article storage article = articles[id];

        
        uint absRate;
        

        if (rate > 0) {
            absRate = uint(rate);
            article.positiveRate += absRate;
        } else {
            absRate = uint(-1 * rate);
            article.negativeRate += absRate;
        }
        
        require(msg.value == absRate * RATEFEE);
        
        article.validators.push(Validator(msg.sender, rate));
        _calculateValidatorScore(article);
        _calculateScore(article);
    }
    
    function reward(uint id) articleExit(id) public payable {
        Article storage article = articles[id];
        article.reward += msg.value;
        _calculateScore(article);
    }
    
    function getReward(uint id) articleExit(id) public {
        Article storage article = articles[id];
        assert(article.date + WITHHOLD_PERIOD > now);
        assert(!article.rewarded);
        
        article.rewarded = true;
        
        if (article.validatorScore >= 0) {
            _rewardPositive(article);
        } else {
            _rewardNegative(article);
        }    
    }
}
