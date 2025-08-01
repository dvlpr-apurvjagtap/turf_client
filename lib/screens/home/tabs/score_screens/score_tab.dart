import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class FootballScoreScreen extends StatefulWidget {
  @override
  _FootballScoreScreenState createState() => _FootballScoreScreenState();
}

class _FootballScoreScreenState extends State<FootballScoreScreen> {
  List<Map<String, dynamic>> games = [];
  final _formKey = GlobalKey<FormState>();
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('football_games');
    if (data != null) {
      setState(() {
        games = List<Map<String, dynamic>>.from(json.decode(data));
      });
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('football_games', json.encode(games));
  }

  void _addGame(String gameName, String location, String date) {
    if (gameName.isNotEmpty) {
      setState(() {
        games.add({
          'gameName': gameName,
          'teams': [],
          'date': date,
          'location': location,
          'id': DateTime.now().millisecondsSinceEpoch.toString()
        });
      });
      _saveData();
    }
  }

  void _addTeam(Map<String, dynamic> game, String teamName, String teamColor) {
    if (teamName.isNotEmpty) {
      setState(() {
        game['teams'].add({
          'teamName': teamName,
          'color': teamColor,
          'players': [],
          'goals': [],
          'logo': '',
          'id': DateTime.now().millisecondsSinceEpoch.toString()
        });
      });
      _saveData();
    }
  }

  void _addPlayer(Map<String, dynamic> team, String playerName, String position,
      String number) {
    if (playerName.isNotEmpty) {
      setState(() {
        team['players'].add({
          'name': playerName,
          'position': position,
          'number': number,
          'id': DateTime.now().millisecondsSinceEpoch.toString()
        });
      });
      _saveData();
    }
  }

  void _addGoal(Map<String, dynamic> team, String playerName, String assist) {
    setState(() {
      team['goals'].add({
        'player': playerName,
        'time': '${DateTime.now().hour}:${DateTime.now().minute}',
        'assist': assist,
        'id': DateTime.now().millisecondsSinceEpoch.toString()
      });
    });
    _saveData();
  }

  void _editGameDetails(
      int gameIndex, String name, String location, String date) {
    setState(() {
      games[gameIndex]['gameName'] = name;
      games[gameIndex]['location'] = location;
      games[gameIndex]['date'] = date;
    });
    _saveData();
  }

  void _deleteGame(int gameIndex) {
    setState(() {
      games.removeAt(gameIndex);
    });
    _saveData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('⚽ Football Tracker'),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green[700]!, Colors.green[400]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: GameSearch(games),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddGameDialog(context),
        label: Text('New Game'),
        icon: Icon(Icons.add),
        backgroundColor: Colors.green,
      ),
      body: games.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView.builder(
                padding: EdgeInsets.all(8),
                itemCount: games.length,
                itemBuilder: (context, index) {
                  final game = games[index];
                  return _buildGameCard(context, game, index);
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sports_soccer, size: 100, color: Colors.grey[400]),
          SizedBox(height: 20),
          Text(
            'No games yet!',
            style: TextStyle(fontSize: 20, color: Colors.grey),
          ),
          Text(
            'Tap the + button to start',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildGameCard(
      BuildContext context, Map<String, dynamic> game, int gameIndex) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () => _showGameDetails(context, game, gameIndex),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      game['gameName'],
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[800],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: Text('Edit'),
                        value: 'edit',
                      ),
                      PopupMenuItem(
                        child: Text('Delete'),
                        value: 'delete',
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showEditGameDialog(context, game, gameIndex);
                      } else if (value == 'delete') {
                        _deleteGame(gameIndex);
                      }
                    },
                  ),
                ],
              ),
              SizedBox(height: 8),
              if (game['location'] != null && game['location'].isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(
                        game['location'],
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              if (game['date'] != null)
                Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(
                        _formatDate(game['date']),
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              if (game['teams'].length >= 2)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildTeamScore(game['teams'][0]),
                    Text(
                      'VS',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    _buildTeamScore(game['teams'][1]),
                  ],
                )
              else if (game['teams'].isNotEmpty)
                _buildTeamScore(game['teams'][0])
              else
                Text(
                  'No teams added yet',
                  style: TextStyle(color: Colors.grey),
                ),
              SizedBox(height: 8),
              LinearProgressIndicator(
                value: game['teams'].length / 2,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  game['teams'].length >= 2 ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamScore(Map<String, dynamic> team) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: _getColorFromString(team['color'] ?? 'blue'),
          child: Text(
            team['teamName'] != null && team['teamName'].isNotEmpty
                ? team['teamName'][0].toUpperCase()
                : '?',
            style: TextStyle(color: Colors.white),
          ),
        ),
        SizedBox(height: 4),
        Text(
          team['teamName'] ?? 'Team',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(
          '${team['goals']?.length ?? 0} goals',
          style: TextStyle(color: Colors.green[700]),
        ),
      ],
    );
  }

  void _showGameDetails(
      BuildContext context, Map<String, dynamic> game, int gameIndex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    game['gameName'],
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Divider(),
              Row(
                children: [
                  Icon(Icons.location_on, color: Colors.grey),
                  SizedBox(width: 8),
                  Text(game['location'] ?? 'No location set'),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.grey),
                  SizedBox(width: 8),
                  Text(_formatDate(game['date'])),
                ],
              ),
              SizedBox(height: 16),
              Expanded(
                child: DefaultTabController(
                  length: game['teams'].length + 1,
                  child: Column(
                    children: [
                      TabBar(
                        isScrollable: true,
                        tabs: [
                          Tab(text: 'Summary'),
                          ...game['teams'].map<Widget>((team) {
                            return Tab(text: team['teamName'] ?? 'Team');
                          }).toList(),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildGameSummary(game),
                            ...game['teams'].map<Widget>((team) {
                              return _buildTeamDetails(team, game);
                            }).toList(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGameSummary(Map<String, dynamic> game) {
    return SingleChildScrollView(
      child: Column(
        children: [
          if (game['teams'].length >= 2)
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        CircleAvatar(
                          backgroundColor: _getColorFromString(
                              game['teams'][0]['color'] ?? 'blue'),
                          radius: 30,
                          child: Text(
                            game['teams'][0]['teamName'] != null &&
                                    game['teams'][0]['teamName'].isNotEmpty
                                ? game['teams'][0]['teamName'][0].toUpperCase()
                                : '?',
                            style: TextStyle(color: Colors.white, fontSize: 20),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          game['teams'][0]['teamName'] ?? 'Team',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${game['teams'][0]['goals']?.length ?? 0}',
                          style:
                              TextStyle(fontSize: 24, color: Colors.green[700]),
                        ),
                      ],
                    ),
                    Text(
                      '-',
                      style: TextStyle(fontSize: 24),
                    ),
                    Column(
                      children: [
                        CircleAvatar(
                          backgroundColor: _getColorFromString(
                              game['teams'][1]['color'] ?? 'red'),
                          radius: 30,
                          child: Text(
                            game['teams'][1]['teamName'] != null &&
                                    game['teams'][1]['teamName'].isNotEmpty
                                ? game['teams'][1]['teamName'][0].toUpperCase()
                                : '?',
                            style: TextStyle(color: Colors.white, fontSize: 20),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          game['teams'][1]['teamName'] ?? 'Team',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${game['teams'][1]['goals']?.length ?? 0}',
                          style:
                              TextStyle(fontSize: 24, color: Colors.green[700]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          if (game['teams'].length < 2)
            Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Add at least 2 teams to track a match',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: () => _showAddTeamDialog(context, game),
                    child: Text('Add Team'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          SizedBox(height: 16),
          if (game['teams'].length >= 2)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Match Events',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 8),
                ..._getMatchEvents(game).map((event) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          _getColorFromString(event['color'] ?? 'blue'),
                      child: Text(
                        event['team'] != null && event['team'].isNotEmpty
                            ? event['team'][0].toUpperCase()
                            : '?',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(event['event'] ?? 'Event'),
                    subtitle: Text(event['time'] ?? 'Time not recorded'),
                  );
                }).toList(),
              ],
            ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getMatchEvents(Map<String, dynamic> game) {
    List<Map<String, dynamic>> events = [];

    for (var team in game['teams']) {
      for (var goal in team['goals']) {
        events.add({
          'team': team['teamName']?.toString() ?? 'Team',
          'color': team['color']?.toString() ?? 'blue',
          'event': '⚽ Goal by ${goal['player']?.toString() ?? 'Player'}',
          'time': goal['time']?.toString() ?? 'Time not recorded'
        });
      }
    }

    // Sort by time (newest first)
    events.sort((a, b) => b['time'].compareTo(a['time']));

    return events;
  }

  Widget _buildTeamDetails(
      Map<String, dynamic> team, Map<String, dynamic> game) {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 16),
          CircleAvatar(
            backgroundColor: _getColorFromString(team['color'] ?? 'blue'),
            radius: 40,
            child: Text(
              team['teamName'] != null && team['teamName'].isNotEmpty
                  ? team['teamName'][0].toUpperCase()
                  : '?',
              style: TextStyle(color: Colors.white, fontSize: 30),
            ),
          ),
          SizedBox(height: 8),
          Text(
            team['teamName'] ?? 'Team',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            '${team['goals']?.length ?? 0} goals',
            style: TextStyle(fontSize: 18, color: Colors.green[700]),
          ),
          SizedBox(height: 16),
          Divider(),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Players',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => _showAddPlayerDialog(context, team),
                  child: Text('Add Player'),
                ),
              ],
            ),
          ),
          ...(team['players'] as List).map<Widget>((player) {
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: _getColorFromString(team['color'] ?? 'blue')
                    .withOpacity(0.2),
                child: Text(player['number']?.toString() ?? '?'),
              ),
              title: Text(player['name']?.toString() ?? 'Player'),
              subtitle:
                  Text(player['position']?.toString() ?? 'Position not set'),
              trailing: IconButton(
                icon: Icon(Icons.sports_soccer, color: Colors.green),
                onPressed: () =>
                    _addGoal(team, player['name']?.toString() ?? 'Player', ''),
              ),
            );
          }).toList(),
          SizedBox(height: 16),
          Divider(),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Goals',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if ((team['players'] as List).isNotEmpty)
                  TextButton(
                    onPressed: () {
                      _showGoalDialog(context, team);
                    },
                    child: Text('Add Goal'),
                  ),
              ],
            ),
          ),
          if ((team['goals'] as List).isEmpty)
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No goals yet',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ...(team['goals'] as List).map<Widget>((goal) {
              return ListTile(
                leading: Icon(Icons.sports_soccer, color: Colors.green),
                title: Text('⚽ ${goal['player']?.toString() ?? 'Player'}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal['time']?.toString() ?? 'Time not recorded'),
                    if (goal['assist']?.toString().isNotEmpty ?? false)
                      Text('Assist: ${goal['assist']}'),
                  ],
                ),
              );
            }).toList(),
          if (game['teams'].length < 2)
            Padding(
              padding: EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () => _showAddTeamDialog(context, game),
                child: Text('Add Another Team'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getColorFromString(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.yellow;
      case 'orange':
        return Colors.orange;
      case 'purple':
        return Colors.purple;
      case 'pink':
        return Colors.pink;
      case 'teal':
        return Colors.teal;
      case 'cyan':
        return Colors.cyan;
      default:
        return Colors.blue;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  void _showAddGameDialog(BuildContext context) {
    final _nameController = TextEditingController();
    final _locationController = TextEditingController();
    final _dateController = TextEditingController(
      text: DateTime.now().toString().split(' ')[0],
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('New Football Game'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Game Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _dateController,
                  decoration: InputDecoration(
                    labelText: 'Date',
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.calendar_today),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          _dateController.text = date.toString().split(' ')[0];
                        }
                      },
                    ),
                  ),
                  readOnly: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _addGame(
                  _nameController.text,
                  _locationController.text,
                  _dateController.text,
                );
                Navigator.pop(context);
              },
              child: Text('Create'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
          ],
        );
      },
    );
  }

  void _showEditGameDialog(
      BuildContext context, Map<String, dynamic> game, int gameIndex) {
    final _nameController = TextEditingController(text: game['gameName']);
    final _locationController =
        TextEditingController(text: game['location'] ?? '');
    final _dateController = TextEditingController(
      text: game['date'] != null
          ? DateTime.parse(game['date']).toString().split(' ')[0]
          : DateTime.now().toString().split(' ')[0],
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Game'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Game Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _dateController,
                  decoration: InputDecoration(
                    labelText: 'Date',
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.calendar_today),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: game['date'] != null
                              ? DateTime.parse(game['date'])
                              : DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          _dateController.text = date.toString().split(' ')[0];
                        }
                      },
                    ),
                  ),
                  readOnly: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _editGameDetails(
                  gameIndex,
                  _nameController.text,
                  _locationController.text,
                  _dateController.text,
                );
                Navigator.pop(context);
              },
              child: Text('Save'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
          ],
        );
      },
    );
  }

  void _showAddTeamDialog(BuildContext context, Map<String, dynamic> game) {
    final _nameController = TextEditingController();
    String _selectedColor = 'blue';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Team to ${game['gameName']}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Team Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedColor,
                  decoration: InputDecoration(
                    labelText: 'Team Color',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    'red',
                    'blue',
                    'green',
                    'yellow',
                    'orange',
                    'purple',
                    'pink',
                    'teal',
                    'cyan'
                  ].map((color) {
                    return DropdownMenuItem<String>(
                      value: color,
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            color: _getColorFromString(color),
                            margin: EdgeInsets.only(right: 8),
                          ),
                          Text(color[0].toUpperCase() + color.substring(1)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    _selectedColor = value!;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _addTeam(game, _nameController.text, _selectedColor);
                Navigator.pop(context);
              },
              child: Text('Add'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
          ],
        );
      },
    );
  }

  void _showAddPlayerDialog(BuildContext context, Map<String, dynamic> team) {
    final _nameController = TextEditingController();
    final _positionController = TextEditingController();
    final _numberController = TextEditingController(
      text: (team['players'].length + 1).toString(),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Player to ${team['teamName']}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Player Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _positionController,
                  decoration: InputDecoration(
                    labelText: 'Position (e.g., Striker, Midfielder)',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _numberController,
                  decoration: InputDecoration(
                    labelText: 'Jersey Number',
                    border: OutlineInputBorder(),
                    // keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _addPlayer(team, _nameController.text, _positionController.text,
                    _numberController.text);
                Navigator.pop(context);
              },
              child: Text('Add'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
          ],
        );
      },
    );
  }

  void _showGoalDialog(BuildContext context, Map<String, dynamic> team) {
    String? _selectedPlayer =
        team['players'].isNotEmpty ? team['players'][0]['name'] : null;
    final _assistController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Goal to ${team['teamName']}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (team['players'].isEmpty)
                  Text('No players available. Add players first.')
                else
                  DropdownButtonFormField<String>(
                    value: _selectedPlayer,
                    decoration: InputDecoration(
                      labelText: 'Scorer',
                      border: OutlineInputBorder(),
                    ),
                    items: (team['players'] as List)
                        .map<DropdownMenuItem<String>>((player) {
                      return DropdownMenuItem<String>(
                        value: player['name'],
                        child: Text('${player['number']}. ${player['name']}'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      _selectedPlayer = value;
                    },
                  ),
                SizedBox(height: 16),
                TextField(
                  controller: _assistController,
                  decoration: InputDecoration(
                    labelText: 'Assist By (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            if (team['players'].isNotEmpty)
              ElevatedButton(
                onPressed: () {
                  if (_selectedPlayer != null) {
                    _addGoal(team, _selectedPlayer!, _assistController.text);
                    Navigator.pop(context);
                  }
                },
                child: Text('Add Goal'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
          ],
        );
      },
    );
  }
}

class GameSearch extends SearchDelegate<String> {
  final List<Map<String, dynamic>> games;

  GameSearch(this.games);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      )
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = games
        .where((game) =>
            game['gameName'].toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final game = results[index];
        return ListTile(
          title: Text(game['gameName']),
          subtitle: Text(game['location'] ?? 'No location'),
          onTap: () {
            close(context, game['gameName']);
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = query.isEmpty
        ? games
        : games
            .where((game) =>
                game['gameName'].toLowerCase().contains(query.toLowerCase()))
            .toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final game = suggestions[index];
        return ListTile(
          title: Text(game['gameName']),
          subtitle: Text(game['location'] ?? 'No location'),
          onTap: () {
            query = game['gameName'];
            showResults(context);
          },
        );
      },
    );
  }
}
