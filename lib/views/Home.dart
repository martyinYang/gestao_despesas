import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestao_despesas/items/ItemFinanceiro.dart';
import 'package:gestao_despesas/views/CadastroDespesas.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  void _navegarParaCadastroDespesas() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => CadastroDespesas(),
    ));
  }

  void _addFunds(String userId) async {
    final TextEditingController _fundsController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Adicionar Fundos'),
          content: TextField(
            controller: _fundsController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(hintText: "Valor do fundo"),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: Text('Adicionar'),
              onPressed: () async {
                final double newFunds =
                    double.tryParse(_fundsController.text) ?? 0;
                DocumentReference userDoc =
                    _db.collection('Credito').doc(userId);

                FirebaseFirestore.instance.runTransaction((transaction) async {
                  DocumentSnapshot snapshot = await transaction.get(userDoc);

                  if (!snapshot.exists) {
                    transaction.set(userDoc, {'saldo_total': newFunds});
                  } else {
                    Map<String, dynamic>? data =
                        snapshot.data() as Map<String, dynamic>?;
                    if (data != null) {
                      double novoSaldoTotal =
                          (data['saldo_total'] as double? ?? 0) + newFunds;
                      transaction
                          .update(userDoc, {'saldo_total': novoSaldoTotal});
                    } else {
                      transaction.set(userDoc, {'saldo_total': newFunds});
                    }
                  }

                  await FirebaseFirestore.instance
                      .collection('EventosCredito')
                      .add({
                    'userId': userId,
                    'valor_adicionado': newFunds,
                    'data': DateTime.now(),
                  });
                });

                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
      ),
      body: Column(
        children: [
          SizedBox(height: 16),
          StreamBuilder<DocumentSnapshot>(
            stream: _db.collection('Credito').doc(userId).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.active &&
                  snapshot.hasData) {
                Map<String, dynamic>? userData =
                    snapshot.data?.data() as Map<String, dynamic>?;
                if (userData != null) {
                  double totalCredit = userData['saldo_total'] ?? 0;
                  return Text('\$$totalCredit',
                      style: Theme.of(context).textTheme.headline4);
                } else {
                  return Text('\$0',
                      style: Theme.of(context).textTheme.headline4);
                }
              } else if (snapshot.hasError) {
                return Text("Erro ao carregar os dados");
              }
              return CircularProgressIndicator(); // 8) toma
            },
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  _addFunds(userId);
                },
                child: Text('Adicionar Fundos'),
              ),
              ElevatedButton(
                onPressed: _navegarParaCadastroDespesas,
                child: Text('Cadastrar despesas'),
              ),
            ],
          ),
          SizedBox(height: 60),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _db
                  .collection('Despesas')
                  .where('userId', isEqualTo: userId)
                  .snapshots(),
              builder: (context, snapshotDespesas) {
                if (!snapshotDespesas.hasData)
                  return CircularProgressIndicator();

                return StreamBuilder<QuerySnapshot>(
                  stream: _db
                      .collection('EventosCredito')
                      .where('userId', isEqualTo: userId)
                      .snapshots(),
                  builder: (context, snapshotEventosCredito) {
                    if (!snapshotEventosCredito.hasData)
                      return CircularProgressIndicator();

                    var itensCombinados = combinarDados(
                        snapshotDespesas.data!, snapshotEventosCredito.data!);

                    return ListView.builder(
                      itemCount: itensCombinados.length,
                      itemBuilder: (context, index) {
                        var item = itensCombinados[index];
                        return ListTile(
                          title: Text(item.titulo),
                          subtitle: Text(item.data),
                          trailing: Text(
                            (item.eDespesa ? '-' : '+') +
                                item.valor.toStringAsFixed(2),
                            style: TextStyle(
                              color: item.eDespesa
                                  ? Colors.red
                                  : Colors
                                      .green, 
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<ItemFinanceiro> combinarDados(
      QuerySnapshot despesas, QuerySnapshot eventosCredito) {
    List<ItemFinanceiro> itens = [];

    despesas.docs.forEach((doc) {
      var data = doc['data'] as Timestamp;
      itens.add(
        ItemFinanceiro(
          titulo: doc['categoria'],
          data: DateFormat('dd/MM/yyyy').format(data.toDate()),
          valor: doc['valor'],
          eDespesa: true,
        ),
      );
    });

    eventosCredito.docs.forEach((doc) {
      var data = doc['data'] as Timestamp;
      itens.add(
        ItemFinanceiro(
          titulo: 'Adição de Fundos',
          data: DateFormat('dd/MM/yyyy').format(data.toDate()),
          valor: doc['valor_adicionado'],
          eDespesa: false,
        ),
      );
    });

    // Ordena os itens por data, se necessário.
    // itens.sort((a, b) => a.data.compareTo(b.data));

    return itens;
  }
}
