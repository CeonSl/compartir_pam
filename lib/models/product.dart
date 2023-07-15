class Product {
  String key = "";
  String nombre;
  int cantidad;
  bool disponibilidad;
  String urlFoto;

  Product(
      {required this.nombre,
      required this.cantidad,
      required this.disponibilidad,
      required this.urlFoto});
}
