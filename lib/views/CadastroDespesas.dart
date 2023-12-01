import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class CadastroDespesas extends StatefulWidget {
  @override
  _CadastroDespesasState createState() => _CadastroDespesasState();
}

class _CadastroDespesasState extends State<CadastroDespesas> {
  final valorFormatter = MaskTextInputFormatter(
    mask: 'R\$ #######',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );
  final dataFormatter = MaskTextInputFormatter(
    mask: '##/##/####',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  final TextEditingController _dataController = TextEditingController();
  final TextEditingController _categoriaController = TextEditingController();
  final TextEditingController _valorController = TextEditingController();
  final TextEditingController _metodoPagamentoController =
      TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  void dispose() {
    _dataController.dispose();
    _categoriaController.dispose();
    _valorController.dispose();
    _metodoPagamentoController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  void atualizarSaldoAposDespesa(String userId) async {
    final valorDespesa =
        double.parse(_valorController.text.replaceAll('R\$', '').trim());

    final userCreditDoc =
        FirebaseFirestore.instance.collection('Credito').doc(userId);

    FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(userCreditDoc);

      if (snapshot.exists && snapshot.data() != null) {
        final userData = snapshot.data() as Map<String, dynamic>;
        final saldoAtual = userData['saldo_total'] as double? ?? 0.0;

        final novoSaldo = saldoAtual - valorDespesa;

        transaction.update(userCreditDoc, {'saldo_total': novoSaldo});
      } else {
        print('Documento de crédito do usuário não encontrado.');
      }
    }).then((result) {
      _valorController.clear();
    }).catchError((error) {
      print('Erro ao atualizar o saldo: $error');
    });
  }

  Future<void> _cadastrarDespesa() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance.collection('Despesas').add({
          'userId': userId,
          'data': _dateFormat.parse(_dataController.text),
          'categoria': _categoriaController.text,
          'valor': double.parse(_valorController.text.replaceAll('R\$', '')),
          'método_pagamento': _metodoPagamentoController.text,
          'descrição': _descricaoController.text.isNotEmpty
              ? _descricaoController.text
              : null,
        });
        atualizarSaldoAposDespesa(userId);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Despesa cadastrada com sucesso!')));
        _dataController.clear();
        _categoriaController.clear();
        _valorController.clear();
        _metodoPagamentoController.clear();
        _descricaoController.clear();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao cadastrar despesa: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cadastro de Despesas'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                controller: _dataController,
                inputFormatters: [dataFormatter],
                keyboardType: TextInputType.datetime,
                decoration: InputDecoration(labelText: 'Data'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Por favor, insira uma data válida.';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _categoriaController,
                decoration: InputDecoration(labelText: 'Categoria'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Por favor, insira uma categoria.';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _valorController,
                inputFormatters: [valorFormatter],
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: 'Valor'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Por favor, insira um valor válido.';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _metodoPagamentoController,
                decoration: InputDecoration(labelText: 'Método de Pagamento'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Por favor, insira um método de pagamento.';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descricaoController,
                decoration: InputDecoration(labelText: 'Descrição (Opcional)'),
              ),
              ElevatedButton(
                onPressed: _cadastrarDespesa,
                child: Text('Cadastrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
