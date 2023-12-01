import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class RelatorioDespesas extends StatefulWidget {
  @override
  _RelatorioDespesasState createState() => _RelatorioDespesasState();
}

class _RelatorioDespesasState extends State<RelatorioDespesas> {
  double totalReceitas = 0;
  double totalDespesas = 0;
  final Map<String, double> categoriaValores = {
    'Food': 0,
    'Shopping': 0,
    'Miscellaneous': 0,
  };

  Map<String, Color> categoriaCores = {
    'Food': Colors.green[400]!,
    'Shopping': Colors.green[600]!,
    'Miscellaneous': Colors.green[800]!,
  };
  List<PieChartSectionData> secoes = [];
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  void fetchData() async {
    double totalReceitasTemp = 0;
    var receitasSnapshot = await FirebaseFirestore.instance
        .collection('Credito')
        .where('userId', isEqualTo: userId)
        .get();
    for (var doc in receitasSnapshot.docs) {
      double valorAdicionado =
          (doc.data()['valor_adicionado'] as num? ?? 0).toDouble();
      totalReceitasTemp += valorAdicionado;
    }
    totalReceitas += totalReceitasTemp;

    var despesasSnapshot = await FirebaseFirestore.instance
        .collection('Despesas')
        .where('userId', isEqualTo: userId)
        .get();
    despesasSnapshot.docs.forEach((doc) {
      String categoria = doc.data()['categoria'];
      double valor = (doc.data()['valor'] as num? ?? 0).toDouble();

      categoriaValores[categoria] = (categoriaValores[categoria] ?? 0) + valor;

      totalDespesas += valor;
    });

    List<PieChartSectionData> secoesTemp =
        categoriaValores.entries.map((entry) {
      final isNotEmpty = entry.value > 0;
      final value = isNotEmpty ? (entry.value / totalDespesas) * 100 : 0;
      return PieChartSectionData(
        value: value.toDouble(),
        title: isNotEmpty ? '${value.toStringAsFixed(1)}%' : '0%',
        color: isNotEmpty ? categoriaCores[entry.key] : Colors.transparent,
        radius: 50,
        titleStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: const Color(0xffffffff),
        ),
        titlePositionPercentageOffset: 0.55,
      );
    }).toList();

    setState(() {
      totalReceitas = totalReceitas;
      totalDespesas = totalDespesas;
      secoes = secoesTemp;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Relatório de Despesas'),
      ),
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Receitas: \$${totalReceitas.toStringAsFixed(2)}',
                  style: TextStyle(
                      color: Colors.green, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Total Despesas: \$${totalDespesas.toStringAsFixed(2)}',
                  style:
                      TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: PieChart(
              PieChartData(
                sections: secoes,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: categoriaValores.entries.map((entry) {
                return Row(
                  children: <Widget>[
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: categoriaCores[entry.key],
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(entry.key),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
