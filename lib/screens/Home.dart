import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Login.dart';
import 'package:http/http.dart' as http;

class UserDetails {
  final String userId;
  final int eloRating;
  final String name;
  final String profilePicUrl;
  final int tournamentsPlayed;
  final int tournamentsWon;
  final int winningPercentage;

  UserDetails(
      {required this.userId,
      required this.eloRating,
      required this.name,
      required this.profilePicUrl,
      required this.tournamentsPlayed,
      required this.tournamentsWon,
      required this.winningPercentage});

  factory UserDetails.fromJson(Map<String, dynamic> json) {
    return UserDetails(
        userId: json['id'],
        eloRating: json['elo'],
        name: json['name'],
        profilePicUrl: json['pic'],
        tournamentsPlayed: json['played'],
        tournamentsWon: json['won'],
        winningPercentage: json['percentage']);
  }
}

class Tournament {
  final String name;
  final String coverUrl;
  final String gameName;

  Tournament(
      {required this.name, required this.coverUrl, required this.gameName});

  factory Tournament.fromJson(dynamic json) {
    return Tournament(
        name: json['name'] as String,
        coverUrl: json['cover_url'] as String,
        gameName: json['game_name'] as String);
  }
}

class TournamentDetails {
  String cursor;
  List<Tournament> tournaments;

  TournamentDetails(this.cursor, this.tournaments);

  factory TournamentDetails.fromJson(dynamic json) {
    if (json['data']['tournaments'] != null) {
      var tournamentObjs = json['data']['tournaments'] as List;
      List<Tournament> _tournaments = tournamentObjs
          .map((tourJson) => Tournament.fromJson(tourJson))
          .toList();
      return TournamentDetails(json['data']['cursor'] as String, _tournaments);
    } else
      return TournamentDetails("", []);
  }

  void addDetails(TournamentDetails newTournamentDetails) {
    this.tournaments.addAll(newTournamentDetails.tournaments);
  }
}

class Home extends StatefulWidget {
  final String? user;
  final bool? isLoggedIn;
  const Home({Key? key, this.user, this.isLoggedIn}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String currentCursor = "";
  late Future<UserDetails> userInfo;
  late SharedPreferences storage;
  late TournamentDetails tournamentDetails;
  static const _pageSize = 10;
  final PagingController<int, Tournament> _pagingController =
      PagingController(firstPageKey: 0);

  final Widget userDetails = Container(
    child: Row(
      children: <Widget>[
        Expanded(
            child: Column(
          children: [
            Text(
              "Welcome to Gamers Hub :)",
              style: TextStyle(color: Color(0xFFFFFFFF)),
            )
          ],
        ))
      ],
    ),
  );

  @override
  void initState() {
    super.initState();
    _loadState();
    userInfo = fetchUserDetails();
    _pagingController.addPageRequestListener((pageKey) {
      fetchTournamentDetails(currentCursor, pageKey);
    });
  }

  void _loadState() async {
    storage = await SharedPreferences.getInstance();
  }

  Future<UserDetails> fetchUserDetails() async {
    String user = widget.user ?? "";
    final response = await http
        .get(Uri.parse('https://gamers-hub-user.herokuapp.com/users/$user'));
    if (response.statusCode == 200) {
      return UserDetails.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load user details');
    }
  }

  Future<void> fetchTournamentDetails(String cursor, int key) async {
    final String BASE_URL =
        "http://tournaments-dot-game-tv-prod.uc.r.appspot.com/tournament/api/tournaments_list_v2?";
    final int limit = 10;
    final String status = "all";
    final response = await http.get(Uri.parse(
        '${BASE_URL}limit=${limit}&status=${status}&cursor=${cursor}'));
    if (response.statusCode == 200) {
      final TournamentDetails newdetails =
          TournamentDetails.fromJson(jsonDecode(response.body));
      final isLastPage = newdetails.tournaments.length < _pageSize;
      currentCursor = newdetails.cursor;
      if (isLastPage) {
        _pagingController.appendLastPage(newdetails.tournaments);
      } else {
        final nextPageKey = key + newdetails.tournaments.length;
        _pagingController.appendPage(newdetails.tournaments, nextPageKey);
      }
    } else {
      throw Exception('Failed to load tournament details');
    }
  }

  Widget getUserTournamentSection(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.50,
      child: PagedListView<int, Tournament>(
        pagingController: _pagingController,
        builderDelegate: PagedChildBuilderDelegate<Tournament>(
            itemBuilder: (context, item, index) {
          return buildRow(item);
        }),
      ),
    );
  }

  Widget buildRow(Tournament row) {
    final double totalWidth = MediaQuery.of(context).size.width * 0.9;
    final double totalHeight = MediaQuery.of(context).size.height * 0.2;
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: ClipRRect(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25), topRight: Radius.circular(25)),
            child: Image.network('${row.coverUrl}',
                width: totalWidth, height: totalHeight, fit: BoxFit.fill),
          ),
        ),
        Container(
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25))),
          width: totalWidth,
          margin: EdgeInsets.only(bottom: 20.0),
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                  child: Container(
                      width: 300,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${row.name}',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${row.gameName}',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 15, color: Color(0xFF9EA5BB)),
                          )
                        ],
                      ))),
              Container(
                child: Column(
                  children: [
                    Icon(
                      Icons.chevron_right_outlined,
                      size: 30,
                      color: Color(0xFF7B7B81),
                    )
                  ],
                ),
              )
            ],
          ),
        )
      ],
    );
  }

  FutureBuilder<UserDetails> getUserProfileSection(
      Future<UserDetails> userFuture) {
    return FutureBuilder(
        future: userFuture,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Container(
                width: MediaQuery.of(context).size.width * 0.9,
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 5),
                      child: Row(
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(300.0),
                              child: Image.network(
                                  '${snapshot.data!.profilePicUrl}',
                                  cacheWidth: 100,
                                  cacheHeight: 100),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 5.0),
                                  child: Text(
                                    '${snapshot.data!.name}',
                                    style: TextStyle(
                                      color: Color(0xFFFFFFFF),
                                      fontSize: 22.0,
                                    ),
                                  ),
                                ),
                                Padding(
                                    padding:
                                        EdgeInsets.symmetric(vertical: 5.0),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          vertical: 10.0, horizontal: 20.0),
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(25),
                                          border: Border.all(
                                              color: Colors.blueAccent)),
                                      child: Row(
                                        children: [
                                          Text(
                                            '${snapshot.data!.eloRating}  ',
                                            style: TextStyle(
                                                fontFamily: 'Arial',
                                                color: Color(0xFF416CFF),
                                                fontSize: 24.0),
                                          ),
                                          Text(
                                            'Elo Rating',
                                            style: TextStyle(
                                                fontFamily: 'Arial',
                                                color: Color(0xFFFFFFFF)),
                                          )
                                        ],
                                      ),
                                    )),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 15.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 15.0, vertical: 30.0),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                  begin: Alignment.topRight,
                                  end: Alignment.bottomLeft,
                                  colors: [
                                    Color(0xFFECA300),
                                    Color(0xFFE37703)
                                  ]),
                              borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  bottomLeft: Radius.circular(20)),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  "${snapshot.data!.tournamentsPlayed}",
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                                Text("Tournaments",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 15)),
                                Text("played",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 15)),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 15.0, vertical: 30.0),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                  begin: Alignment.topRight,
                                  end: Alignment.bottomLeft,
                                  colors: [
                                    Color(0xFFA757BF),
                                    Color(0xFF412196)
                                  ]),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '${snapshot.data!.tournamentsWon}',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                                Text(
                                  "Tournaments",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 15),
                                ),
                                Text("won",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 15)),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 15.0, vertical: 30.0),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                  begin: Alignment.topRight,
                                  end: Alignment.bottomLeft,
                                  colors: [
                                    Color(0xFFEF7F50),
                                    Color(0xFFEC5144)
                                  ]),
                              borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(20),
                                  bottomRight: Radius.circular(20)),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '${snapshot.data!.winningPercentage}%',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                                Text("Winning",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 15)),
                                Text("percentage",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 15)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ));
          }

          return Container(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.0),
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      "Loading...",
                      style: TextStyle(color: Colors.white),
                    )
                  ],
                )
              ],
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Color(0xFF2E2D32),
          title: Text('Flyingwolf'),
          brightness: Brightness.dark,
          centerTitle: true,
          automaticallyImplyLeading: false,
          leading: Icon(Icons.menu),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: getUserProfileSection(userInfo),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
              child: Container(
                child: Row(
                  children: [
                    Text("Recommended For You",
                        style: TextStyle(fontSize: 22, color: Colors.white))
                  ],
                ),
              ),
            ),
            Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 5.0, horizontal: 5.0),
                child: getUserTournamentSection(context))
          ],
        ),
      ),
    );
  }
}
