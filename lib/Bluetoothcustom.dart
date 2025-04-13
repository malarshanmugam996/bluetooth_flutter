import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothCustomDevice {
  BluetoothAdapterState adapterState = BluetoothAdapterState.unknown;
  List<BluetoothDevice> systemDevices = [];
  List<ScanResult> scanResults = [];
  List<BluetoothService> services = [];
  late StreamSubscription<List<ScanResult>> scanResultsSubscription;
  late StreamSubscription<BluetoothAdapterState> adapterStateStateSubscription;
  BluetoothConnectionState connectionState = BluetoothConnectionState.disconnected;
  late StreamSubscription<BluetoothConnectionState> connectionStateSubscription;
  BluetoothCustomDevice();

  setBLESettings(List<String> configDict){
    adapterStateStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      adapterState = state;
    });
   // return _adapterState;
  }
   Future<List<ScanResult>> scanForPeripherals() async {

    await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
        withServices: [],
        webOptionalServices: []
      //Guid("180f"), // battery
      // Guid("1800"), // generic access
      // Guid("6e400001-b5a3-f393-e0a9-e50e24dcca9e"), // Nordic UART

    );
    scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      scanResults = results;

    }, onError: (e) {
      print("Scan Error:"+ e.toString());
    });
    return scanResults;
  }
  Future<List<ScanResult>> scanForPeripheralswithserviceid(List<Guid>ServicesGuid,List<Guid>withServices,List<Guid>webOptionalServices ) async {
     
   try {
      
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
        withServices: withServices,
        webOptionalServices: webOptionalServices
          //Guid("180f"), // battery
          // Guid("1800"), // generic access
          // Guid("6e400001-b5a3-f393-e0a9-e50e24dcca9e"), // Nordic UART

      );
    
    } catch (e, backtrace) {
     // Snackbar.show(ABC.b, prettyException("Start Scan Error:", e), success: false);
      print(e);
      print("backtrace: $backtrace");
    }
    scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      scanResults = results;

    }, onError: (e) {
      print("Scan Error:"+ e.toString());
    });
    return scanResults;
  }
  stopPeripheralScan(){
    try {
      FlutterBluePlus.stopScan();
    } catch (e, backtrace) {
      print(e);
      print("backtrace: $backtrace");
    }
  }

 discoverServicesCharacteristicsForConnectedPeripheral(
      BluetoothDevice device,
      Guid serviceUuid,
      Guid writeCharUuid,
      List<int> value, {
        Guid? responseCharUuid, // optional, if response comes in a different char
      }) async {
    BluetoothCharacteristic? writeChar;
    BluetoothCharacteristic? responseChar;
    List<int>values=[];
    try {
      var services = await device.discoverServices();

      for (var service in services) {
        if (service.uuid == serviceUuid) {
          for (var c in service.characteristics) {
            if (c.uuid == writeCharUuid) {
              writeChar = c;
            }
            if (responseCharUuid != null && c.uuid == responseCharUuid) {
              responseChar = c;
            }
          }
        }
      }

      if (writeChar != null) {
        await writeChar.write(value, withoutResponse: false);
        print("✅ Write successful");

        if (responseChar != null) {

          await Future.delayed(const Duration(milliseconds: 300)); // optional delay
          var response = await responseChar.read();
            writeChar?.value.listen((value) {
              values=value;
            });
          print("📥 Response: $response");
        }
      } else {
        print("❌ Writable characteristic not found");
      }
    } catch (e, backtrace) {
      print("❌ Error: $e");
      print("Backtrace: $backtrace");
    }

    return values;
  }

  Future<BluetoothCharacteristic?> findWritableCharacteristic(
      BluetoothDevice device, Guid serviceUuid, Guid charUuid) async {
    List<BluetoothService> services = await device.discoverServices();
    for (BluetoothService service in services) {
      if (service.uuid == serviceUuid) {
        for (BluetoothCharacteristic characteristic in service.characteristics) {
          if (characteristic.uuid == charUuid &&
              (characteristic.properties.write || characteristic.properties.writeWithoutResponse)) {
            return characteristic;
          }
        }
      }
    }
    return null;
  }

  discoverServicesCharacteristics(BluetoothDevice device) async {

    try {
      services = await device.discoverServices();

    } catch (e, backtrace) {
      print(e);
      print("backtrace: $backtrace");
    }
  return services;
  }
   connect(BluetoothDevice device) async {
    bool  isConnected=false;
    try {
      await device.connect();

      connectionStateSubscription = device.connectionState.listen((state) {
        connectionState = state;

      });
      //isConnected= connectionState == BluetoothConnectionState.connected;
    } catch (e, backtrace) {
      if (e is FlutterBluePlusException && e.code == FbpErrorCode.connectionCanceled.index) {
        // ignore connections canceled by the user
      } else {
        print(e);
        print("backtrace: $backtrace");
      }
    }
    return isConnected!;
  }

  disconnect(BluetoothDevice device) async {
    bool  isConnected=false;
    try {
      await device.disconnect();
      connectionStateSubscription = device.connectionState.listen((state) {
        connectionState = state;

      });
      isConnected= connectionState == BluetoothConnectionState.connected;

    } catch (e, backtrace) {
      print("$e backtrace: $backtrace");
    }
    return isConnected;
  }
}
