import 'package:flutter/material.dart';

import '../core/app_colors.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Text('Seus melhores Matches', style: TextStyle(fontSize: 18)),
              ],
            ),

            Row(
              children: [
                Text(
                  'Amiguinhos que combinam com você!',
                  style: TextStyle(fontSize: 14, color: Color(0xFF888888)),
                ),
              ],
            ),

            SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const minCardWidth = 160.0;

                  const spacing = 8.0;

                  final columns =
                      ((constraints.maxWidth + spacing) /
                              (minCardWidth + spacing))
                          .floor()
                          .clamp(1, 100);

                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    crossAxisCount: columns,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 167 / 162,
                    children: const [
                      _PetCard(
                        name: 'Bolt',
                        age: '1 ano',
                        gender: 'Macho',
                        match: 95,
                        image: 'https://images.unsplash.com/photo-1583511655857-d19b40a7a54e?w=500&h=340&fit=crop',
                      ),
                      _PetCard(
                        name: 'Rubi',
                        age: '4 anos',
                        gender: 'Fêmea',
                        match: 80,
                        image: 'https://images.unsplash.com/photo-1546527868-ccb7ee7dfa6a?w=500&h=340&fit=crop',
                      ),
                      _PetCard(
                        name: 'Brutos',
                        age: '2 anos',
                        gender: 'Macho',
                        match: 60,
                        image: 'https://images.unsplash.com/photo-1551717743-49959800b1f6?w=500&h=340&fit=crop',
                      ),
                      _PetCard(
                        name: 'Brutus',
                        age: '4 meses',
                        gender: 'Macho',
                        match: 55,
                        image: 'https://images.unsplash.com/photo-1518717758536-85ae29035b6d?w=500&h=340&fit=crop',
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PetCard extends StatefulWidget {
  const _PetCard({
    required this.name,
    required this.age,
    required this.gender,
    required this.match,
    required this.image,
  });

  final String name;
  final String age;
  final String gender;
  final int match;
  final String image;

  @override
  State<_PetCard> createState() => _PetCardState();
}

class _PetCardState extends State<_PetCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.laranja, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagem do pet
          AspectRatio(
            aspectRatio: 167 / 116,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.network(
                    widget.image,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.rosaClaro,
                        child: const Center(
                          child: Icon(
                            Icons.pets,
                            size: 48,
                            color: AppColors.laranja,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                Positioned(
                  left: 5,
                  bottom: 7,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCE7DC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.pets_outlined,
                          size: 15,
                          color: AppColors.laranja,
                        ),
                        const SizedBox(width: 3),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${widget.match}%',
                              style: const TextStyle(
                                fontSize: 10,
                                height: 1,
                                color: AppColors.laranja,
                              ),
                            ),
                            const Text(
                              'compatibilidade',
                              style: TextStyle(
                                fontSize: 6,
                                height: 1.2,
                                color: AppColors.laranja,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Informações do pet
          Padding(
            padding: const EdgeInsets.only(left: 7, top: 1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.name,
                  style: const TextStyle(fontSize: 14, height: 1.05),
                ),
                _detail(Icons.access_time, widget.age),
                _detail(
                  widget.gender == 'Fêmea' ? Icons.female : Icons.male,
                  widget.gender,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detail(IconData icon, String text) => Row(
    children: [
      Icon(icon, size: 11, color: const Color(0xFFAAAAAA)),
      const SizedBox(width: 3),
      Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          height: 1.15,
          color: Color(0xFFAAAAAA),
        ),
      ),
    ],
  );
}
