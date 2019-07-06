# RegExSwift

RegExSwft converts your regular expression to a NFA, and shows you how regular expression matching is done and what the heck is going on behind this matching magic with a dynamic graph.

![](example.gif)

Why this project:
When I was reading [The Dragon Book](https://en.wikipedia.org/wiki/Compilers:_Principles,_Techniques,_and_Tools), I found concepts like NFA/DFA difficult to understand. However, as the foundation of regular expression, NFA is an important shit in computer science. There is no better way to study one thing than make it all over again.

Besides, I believe RegExSwift is a good tool for anyone struggling to understand regular expression and how it works.

Detail:
RegExSwift parses regular expression with its own parsing engine written in Swift. Then it creates NFAs with the parsing result. Finally, it renders the NFAs to png with Graphviz.

## Getting Started

clone this repo to your folder.

open RegSwiftProject.xcworkspace with Xcode.

Run MacApp target.

## Authors

* **White** - *Initial work* - [White](https://github.com/White-White)

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details

## Acknowledgments

* I learned these shits from [The Dragon Book](https://en.wikipedia.org/wiki/Compilers:_Principles,_Techniques,_and_Tools)
* This project is heavily inpired the work of [Russ Cox](https://swtch.com/~rsc/). One lost soul (like me) can find some great articles about regular expression from [Regular Expression Matching Can Be Simple And Fast](https://swtch.com/~rsc/regexp/regexp1.html)
* This project is a good example of using [Graphviz](https://www.graphviz.org/) as a c-library in your project. Many thanks to people behind Graphviz.

