import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WeatherApp',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Accueil'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Bienvenue sur WeatherApp',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProgressScreen()),
                );
              },
              child: Text('Commencer'),
            ),
          ],
        ),
      ),
    );
  }
}

class ProgressScreen extends StatefulWidget {
  @override
  _ProgressScreenState createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen>
    with SingleTickerProviderStateMixin{
  double progressPercentage = 0.0;
  Timer? timer;
  late AnimationController _animationController;
  late Animation<double> progressAnimation;
  int messageIndex = 0;
  bool animationComplete = false;
  int apiCallCount = 0;
  List<String> messages = [
    'Nous téléchargeons les données...',
    'C\'est presque fini...',
    'veuillez patienter',
    'Plus que quelques secondes avant d\'avoir le résultat...'
  ];
 // int messageIndex = 0;
  List<WeatherData> weatherDataList = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 10),
    );

    progressAnimation = Tween<double>(begin: 0, end: 100).animate(_animationController)
      ..addListener(() {
        setState(() {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            animationComplete = true;
          });
        }
      });

    startProgress();

    _startAnimation();
    timer = Timer.periodic(Duration(milliseconds: 10), (Timer t) {
      if (apiCallCount < 5) {
        fetchData();
        apiCallCount++;
      }
    });
    timer = Timer.periodic(Duration(milliseconds: 100), (Timer t) {
      changeMessage();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();

    timer?.cancel();
    super.dispose();
  }
  void _startAnimation() {
    animationComplete = false;
    _animationController.reset();
    _animationController.forward();
  }
  void startProgress() {
    Timer.periodic(Duration(milliseconds: 100), (Timer t) {
      setState(() {
        progressPercentage += 1.67;
        if (progressPercentage >= 100.0) {

          t.cancel();
          fetchData();
        }
      });
    });
  }

  void changeMessage() {
    setState(() {
      messageIndex = (messageIndex + 1) % messages.length;
    });
  }

  Future<void> fetchData() async {
    List<String> cities = ['Rennes', 'Paris', 'Nantes', 'Bordeaux', 'Lyon'];
    String apiKey = '1fe92a46bec2888cd85e476d323d84d9';
    String apiUrl = 'https://api.openweathermap.org/data/2.5/weather';

    for (int i = 0; i < cities.length; i++) {
      String city = cities[i];
      String url = '$apiUrl?q=$city&appid=$apiKey';

      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        WeatherData weatherData = WeatherData(
          city: city,
          temperature: data['main']['temp'],
          cloudiness: data['clouds']['all'],
        );
        weatherDataList.add(weatherData);
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Weather'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  messages[messageIndex],
                  style: TextStyle(fontSize: 24),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                LinearProgressIndicator(
                  value: progressPercentage / 100.0,
                  minHeight: 35,
                  backgroundColor: Colors.pinkAccent,
                  valueColor: AlwaysStoppedAnimation(Colors.grey),
                ),
                SizedBox(height: 50),
                Text(
                  '${progressPercentage.toInt()}%',
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),
          ),
          if (progressPercentage >= 100.0 && weatherDataList.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: weatherDataList.length,
                itemBuilder: (context, index) {
                  WeatherData weatherData = weatherDataList[index];
                  return ListTile(
                    title: Text(weatherData.city),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Température: ${weatherData.temperature}°C'),
                        Text('Couverture nuageuse: ${weatherData.cloudiness}%'),
                      ],
                    ),
                  );
                },
              ),
            ),
          
          if (progressPercentage >= 100.0)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Recommencer'),
            ),
        ],
      ),
    );
  }
}

class WeatherData {
  final String city;
  final double temperature;
  final int cloudiness;

  WeatherData({
    required this.city,
    required this.temperature,
    required this.cloudiness,
  });
}
