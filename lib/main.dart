import 'package:compartir_pam/models/product.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MainApp());
}

Map<String, dynamic> mapResponse = {};
final _messangerKey = GlobalKey<ScaffoldMessengerState>();

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  List<Product> products = [];

  Future<void> recieveProducts() async {
    http.Response response;
    response = await http.get(Uri.parse(
        "https://compartir-pam-default-rtdb.firebaseio.com/productos.json"));
    if (response.statusCode == 200 && json.decode(response.body) != null) {
      setState(() {
        mapResponse = json.decode(response.body);
        for (var entry in mapResponse.entries) {
          Product producto = Product(
              nombre: '', cantidad: 0, disponibilidad: true, urlFoto: '');
          String key = entry.key;
          String nombre = entry.value["nombre"];
          int cantidad = entry.value["cantidad"];
          bool disponibilidad = entry.value["disponibilidad"];
          String urlFoto = entry.value["urlFoto"];

          producto.key = key;
          producto.nombre = nombre;
          producto.cantidad = cantidad;
          producto.disponibilidad = disponibilidad;
          producto.urlFoto = urlFoto;
          products.add(producto);
        }
      });
    } else {}
  }

  void showSnackbar(BuildContext context, String message, Color color) {
    _messangerKey.currentState!.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == const Color.fromARGB(255, 211, 198, 12)
                  ? Icons.warning_amber_outlined
                  : color == Colors.red
                      ? Icons.close
                      : Icons.check,
              color: Colors.white,
            ),
            Text(
              message,
            ),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> addCompromiso(nombre, cantidad, producto) async {
    http.Response responseValidate;
    http.Response response;
    http.Response responseCompromiso;
    Map<String, dynamic> productoRecieved = {};

    String sendKey = Uri.encodeFull(producto.key);

    responseValidate = await http.get(Uri.parse(
        "https://compartir-pam-default-rtdb.firebaseio.com/productos/$sendKey.json"));

    if (responseValidate.statusCode == 200) {
      productoRecieved = json.decode(responseValidate.body);
      Product productoToCompare =
          Product(nombre: '', cantidad: 0, disponibilidad: true, urlFoto: '');
      int cantidad = productoRecieved.entries.first.value;
      productoToCompare.cantidad = cantidad;
      if (productoToCompare.cantidad != producto.cantidad) {
        products.clear();
        recieveProducts();
        // ignore: use_build_context_synchronously
        showSnackbar(context,
            "Fueron actualizados los productos, envía de nuevo", Colors.red);
      } else {
        num changeQuantity = productoToCompare.cantidad.round() - cantidad;
        Map<String, dynamic> modifyQuantity = {
          "cantidad": changeQuantity,
        };

        if (changeQuantity == 0) {
          modifyQuantity = {
            "cantidad": changeQuantity,
            "disponibilidad": false
          };
        }
        response = await http.patch(
            Uri.parse(
                "https://compartir-pam-default-rtdb.firebaseio.com/productos/$sendKey.json"),
            body: jsonEncode(modifyQuantity));
        if (response.statusCode == 200) {
          Map<String, dynamic> sendData = {
            "persona": nombre,
            "cantidad": cantidad,
            "producto": producto.nombre
          };

          responseCompromiso = await http.post(
              Uri.parse(
                  "https://compartir-pam-default-rtdb.firebaseio.com/compromiso.json"),
              body: jsonEncode(sendData));
          if (responseCompromiso.statusCode == 200) {
            products.clear();
            recieveProducts();
            // ignore: use_build_context_synchronously
            showSnackbar(context, "Enviado correctamente", Colors.green);
          } else {}
        } else {}
      }
    }
  }

  Future<void> reloadApp() async {
    products.clear();
    recieveProducts();
    showSnackbar(context, "Productos Actualizados", Colors.green);
  }

  @override
  void initState() {
    recieveProducts();
    super.initState();
  }

  TextEditingController nombre = TextEditingController();
  TextEditingController cantidad = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: _messangerKey,
      home: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text('Compartir PAM'),
            backgroundColor: Colors.green,
          ),
          // Create the SelectionButton widget in the next step.
          body: RefreshIndicator(
              onRefresh: reloadApp,
              child: Builder(builder: ((BuildContext context) {
                return GridView.count(
                  crossAxisCount: 2,
                  children: List.generate(products.length, (index) {
                    return Column(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(5),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Expanded(
                                          child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            0, 0, 5, 0),
                                        child: SizedBox(
                                          width: 120,
                                          height: 120,
                                          child: Image(
                                              image: NetworkImage(
                                                  products[index].urlFoto)),
                                        ),
                                      )),
                                      Expanded(
                                          child: Column(
                                        children: [
                                          Text(
                                            products[index].nombre,
                                            style: const TextStyle(
                                                color: Colors.black),
                                          ),
                                          Text(
                                            "Disponible: ${products[index].cantidad}",
                                            style: TextStyle(
                                                color: products[index]
                                                        .disponibilidad
                                                    ? Colors.black
                                                    : Colors.red),
                                          )
                                        ],
                                      ))
                                    ],
                                  ),
                                ),
                                ElevatedButton.icon(
                                    onPressed: () => {
                                          if (products[index].disponibilidad)
                                            {
                                              showDialog(
                                                  context: context,
                                                  builder:
                                                      ((BuildContext context) {
                                                    return AlertDialog(
                                                        title: const Text(
                                                            "Llevarás?"),
                                                        content:
                                                            SingleChildScrollView(
                                                          child: Column(
                                                            children: [
                                                              TextField(
                                                                controller:
                                                                    nombre,
                                                                decoration: const InputDecoration(
                                                                    hintText:
                                                                        "Nombre completo",
                                                                    prefixIcon: Icon(
                                                                        Icons
                                                                            .person_2_outlined,
                                                                        color: Colors
                                                                            .black)),
                                                              ),
                                                              const SizedBox(
                                                                height: 20.0,
                                                              ),
                                                              TextField(
                                                                controller:
                                                                    cantidad,
                                                                decoration: const InputDecoration(
                                                                    hintText:
                                                                        "Cantidad",
                                                                    prefixIcon: Icon(
                                                                        Icons
                                                                            .numbers_outlined,
                                                                        color: Colors
                                                                            .black)),
                                                              ),
                                                              const SizedBox(
                                                                height: 20.0,
                                                              ),
                                                              RawMaterialButton(
                                                                fillColor:
                                                                    Colors
                                                                        .green,
                                                                elevation: 0.0,
                                                                padding: const EdgeInsets
                                                                        .symmetric(
                                                                    vertical:
                                                                        5.0),
                                                                shape: RoundedRectangleBorder(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            5.0)),
                                                                onPressed: () {
                                                                  String
                                                                      nombreSend =
                                                                      nombre
                                                                          .text
                                                                          .toString();
                                                                  String
                                                                      cantidadSend =
                                                                      cantidad
                                                                          .text
                                                                          .toString();

                                                                  if (nombreSend
                                                                          .isEmpty ||
                                                                      cantidadSend
                                                                          .isEmpty) {
                                                                    showSnackbar(
                                                                        context,
                                                                        "Debes ingresar todos los datos",
                                                                        const Color.fromARGB(
                                                                            255,
                                                                            211,
                                                                            198,
                                                                            12));
                                                                  } else if (int
                                                                          .parse(
                                                                              cantidadSend) >
                                                                      products[
                                                                              index]
                                                                          .cantidad) {
                                                                    showSnackbar(
                                                                        context,
                                                                        "El máximo son: ${products[index].cantidad}",
                                                                        const Color.fromARGB(
                                                                            255,
                                                                            211,
                                                                            198,
                                                                            12));
                                                                  } else {
                                                                    addCompromiso(
                                                                        nombreSend,
                                                                        int.parse(
                                                                            cantidadSend),
                                                                        products[
                                                                            index]);

                                                                    Navigator.pop(
                                                                        context);
                                                                  }
                                                                },
                                                                child:
                                                                    const Padding(
                                                                  padding:
                                                                      EdgeInsets
                                                                          .all(
                                                                              12.0),
                                                                  child: Text(
                                                                    "Comprometerse",
                                                                    style: TextStyle(
                                                                        color: Colors
                                                                            .white,
                                                                        fontSize:
                                                                            15.0),
                                                                  ),
                                                                ),
                                                              )
                                                            ],
                                                          ),
                                                        ));
                                                  }))
                                            }
                                        },
                                    icon: const Icon(
                                      Icons.shopping_cart,
                                      size: 12.0,
                                    ),
                                    style: ButtonStyle(
                                      backgroundColor: MaterialStateProperty
                                          .resolveWith<Color?>((states) {
                                        if (!products[index].disponibilidad) {
                                          // Set the disabled color
                                          return Colors.grey;
                                        } else {
                                          // Set the enabled color
                                          return Colors.green;
                                        }
                                      }),
                                    ),
                                    label: const Text("Llevaré")),
                              ],
                            ),
                          ),
                        )
                      ],
                    );
                  }),
                );
              })))),
    );
  }
}
