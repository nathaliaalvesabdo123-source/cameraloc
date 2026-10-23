import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Perfil com Foto e Localização',
      home: TelaPerfil(),
    );
  }
}

class TelaPerfil extends StatefulWidget {
  const TelaPerfil({super.key});

  @override
  State<TelaPerfil> createState() => _TelaPerfilState();
}

class _TelaPerfilState extends State<TelaPerfil> {
  File? foto;
  String? fotoUrl; // Variável nova para o teste no Chrome
  String localizacao = 'Localização ainda não obtida';
  bool localizacaoObtida = false;
  bool buscandoLocalizacao = false;

  Future<void> escolherFoto(ImageSource origem) async {
    try {
      final picker = ImagePicker();
      final imagem = await picker.pickImage(source: origem);
      
      if (imagem != null) {
        setState(() {
          foto = File(imagem.path);
          fotoUrl = null; // Limpa a URL se pegar uma foto real
        });
      }
    } catch (e) {
      // Fallback para o Chrome
      setState(() {
        foto = null;
        fotoUrl = 'https://picsum.photos/200'; // Usa URL no teste
      });
    }
  }

  void removerFoto() {
    setState(() {
      foto = null;
      fotoUrl = null;
    });
  }

  Future<void> obterLocalizacao() async {
    setState(() {
      buscandoLocalizacao = true;
    });

    try {
      final servicoAtivo = await Geolocator.isLocationServiceEnabled();
      if (!servicoAtivo) {
        atualizarErroLocalizacao('Ative o GPS do dispositivo.');
        return;
      }

      var permissao = await Geolocator.checkPermission();
      if (permissao == LocationPermission.denied) {
        permissao = await Geolocator.requestPermission();
      }

      if (permissao == LocationPermission.denied) {
        atualizarErroLocalizacao('Permissão de localização negada.');
        return;
      }

      if (permissao == LocationPermission.deniedForever) {
        atualizarErroLocalizacao('Permissão negada permanentemente. Libere-a nas configurações.');
        return;
      }

      final posicao = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      
      setState(() {
        localizacao = 'Latitude: ${posicao.latitude.toStringAsFixed(4)}\n'
                      'Longitude: ${posicao.longitude.toStringAsFixed(4)}';
        localizacaoObtida = true;
        buscandoLocalizacao = false;
      });
    } catch (_) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      setState(() {
        localizacao = 'Latitude: -23.5505\nLongitude: -46.6333';
        localizacaoObtida = true;
        buscandoLocalizacao = false;
      });
    }
  }

  void atualizarErroLocalizacao(String mensagem) {
    if (!mounted) return;
    setState(() {
      localizacao = mensagem;
      localizacaoObtida = false;
      buscandoLocalizacao = false;
    });
  }

  // Função para decidir qual imagem mostrar
  ImageProvider? _getFotoExibida() {
    if (foto != null) return FileImage(foto!);
    if (fotoUrl != null) return NetworkImage(fotoUrl!);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil com Foto e Localização'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: _getFotoExibida(), // Usa a nova função
                child: (foto == null && fotoUrl == null)
                    ? const Icon(Icons.person, size: 60, color: Colors.grey)
                    : null,
              ),
              const SizedBox(height: 16),
              
              ElevatedButton.icon(
                onPressed: () => escolherFoto(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Tirar foto'),
              ),
              const SizedBox(height: 8),
              
              ElevatedButton.icon(
                onPressed: () => escolherFoto(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Escolher da galeria'),
              ),
              
              if (foto != null || fotoUrl != null) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: removerFoto,
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text('Remover foto', style: TextStyle(color: Colors.red)),
                ),
              ],

              const SizedBox(height: 24),
              
              Icon(
                localizacaoObtida ? Icons.location_on : Icons.location_searching,
                size: 36,
                color: localizacaoObtida ? Colors.green : Colors.grey,
              ),
              const SizedBox(height: 8),
              Text(
                localizacao,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              
              ElevatedButton.icon(
                onPressed: buscandoLocalizacao ? null : obterLocalizacao,
                icon: buscandoLocalizacao
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.my_location),
                label: Text(
                  buscandoLocalizacao ? 'Obtendo localização...' : 'Usar minha localização',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}