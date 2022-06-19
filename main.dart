import 'dart:async';

import 'package:flutter/material.dart';
import 'dart:ui';

import 'package:flutter/services.dart';///dart和原生混合开发模式
void main() => runApp(MyApp(initParams: window.defaultRouteName));

class MyApp extends StatelessWidget {
  final String? initParams;
  const MyApp({Key? key, this.initParams}): super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(
          title: 'Flutter 混合开发',
          initParams:initParams),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({required this.title,required this.initParams});
  final String title;
  final String? initParams;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  ///EventChannel
  static const EventChannel _eventChannel = EventChannel('EventChannelPlugin');
  ///methodchannel
  static const MethodChannel _methodChannel = MethodChannel('MethodChannelPlugin');

  ///basicMessageChannel
  static const BasicMessageChannel<String> _basicMessageChannel = BasicMessageChannel('BasicMessageChannelPlugin', StringCodec());

  ///接收iOS返回的值
  String showMessage = '';

  StreamSubscription? _streamSubscription;

  bool _isMethodChannelPlugin = false;
  @override
  void initState() {
    ///注册监听,并携带参数给native
    _streamSubscription = _eventChannel.receiveBroadcastStream('110')
        .listen(onToDart,onError: _onToDartError);
    //使用BasicMessageChannel接收来自Native的消息，并向Native回复
    _basicMessageChannel.setMessageHandler((message) => Future<String>((){
      setState((){
        showMessage ='BasicMessageChannel:${message!}';
      });
      return "收到Native的消息：${message!}";
    }));
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
  }

  ///原生传数据时调用此函数
  void onToDart(message){
    setState((){
      showMessage = message;
    });
  }

  void _onToDartError(error){
    print(error);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Container(
        alignment: Alignment.topCenter,
        decoration: BoxDecoration(color: Colors.lightBlueAccent),
        margin: EdgeInsets.only(top: 70),
        child: Column(
          children: [
            SwitchListTile(
                value: _isMethodChannelPlugin,
                onChanged: _onChannelChange,
                title: Text(_isMethodChannelPlugin ? "MethodChannelPlugin" : "BasicMessageChannelPlugin")
            ),
            TextField(
              onChanged: _onTextChange,
              decoration: InputDecoration(
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white)),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white))),
            ),
            Text('收到初始化参数initParams: ${widget.initParams}'),
            Text('Native传来的消息:' + showMessage),
          ],
        ),
      ),
    );
  }

  void _onChannelChange(bool value) {
    setState((){
      _isMethodChannelPlugin = value;
    });
  }

  void _onTextChange(value) async {
      String? response;
      try{
        if(_isMethodChannelPlugin){
          response = (await _methodChannel.invokeListMethod('send',value)) as String;
        } else {
          response = await _basicMessageChannel.send(value);
        }
      }on PlatformException catch (e){
          print(e);
        }
  }
}
