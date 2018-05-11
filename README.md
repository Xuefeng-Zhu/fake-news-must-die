# fake-news-must-die
kill fake news with blockchain and reward valuable content
![logo](/assets/fake_news.png)

## Problem:
* There are too many information in the internet these days. People have trouble to identify valuable information
* Authors of content gets paid generally through ads. As ad blocker gets popular, the income for content creators are declining
Censorship, political sensitive information is hidden/forbidden
* More destructively, fake news are everywhere on social network, mislead people, discredit media and even cause panics.

## Solution
A news/information platform based on blockchain
* Reward content creator
* Punish bad characters
* Published contents cannot be easily manipulated by third party

## How this contract will work

### Three roles
1. Publisher
1. Validator
1. Reader

### Flow
1. Publisher needs to deposit ether to get content published, the more ether deposits, the higher the rank will be
1. Validator will validate content quality, rate from -5 to 5, in order to rate validator needs to deposit ether, the amount of ether will be proportional to the rating. The rate will affect the rank of article
1. Reader will reward high quality article with ether, reward will also affect rank of article
1. After a certain time (ex. 1 day), publisher/validators will be able to withdraw deposit. If the average rating of the content is positive, then publisher and positive validators will be able to withdraw their deposits, and they are able to get dividend from reader reward and negative validators deposit. Sound familiar It is quite similar how stock system works . Publisher and validators are shareholders, and readers are consumers. Otherwises, negatives validators will be able to withdraw their deposits, and get dividend from reader reward and publisher and positive validators deposits.

### Reputation system (Long term strategy, You need to be a good citizen)

Each participant can buy reputation with ether at the beginning. The reputation of well behaved participants will increase. The reputation of misbehaved participants will decrease. Reputation will influence the ranking of articles. 


## Ranking Algorithm

* P = Publisher Deposit
* PR = Publisher reputation
* RW = Reader reward
* VS = Valiators rating
* T = hours since submission
* G = Gravity
* P = Publisher Deposit

Score= (P+PR+RW+(for V in VS (V.rating*V.reputation)) /VS.count ) .(T+1)^G 

