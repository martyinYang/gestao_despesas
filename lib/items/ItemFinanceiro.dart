class ItemFinanceiro {
  final String titulo;
  final String data;
  final double valor;
  final bool eDespesa;

  ItemFinanceiro({
    required this.titulo,
    required this.data,
    required this.valor,
    this.eDespesa = true,
  });
}
