import 'package:entre_patas/view/animal/fichaAnimal.dart';
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../usuario/fichaPerfil.dart';

class PesquisaScreen extends StatefulWidget {
  const PesquisaScreen({super.key});

  @override
  State<PesquisaScreen> createState() => _PesquisaScreenState();
}

class _PesquisaScreenState extends State<PesquisaScreen> {

  static const List<List> animais = [
    ["Bolt", "1 ano", "Macho", "https://images.unsplash.com/photo-1583511655857-d19b40a7a54e?w=500&h=340&fit=crop"],
    ["Rubi", "4 anos", "Fêmea", "https://images.unsplash.com/photo-1546527868-ccb7ee7dfa6a?w=500&h=340&fit=crop"],
    ["Brutos", "2 anos", "Macho", "https://images.unsplash.com/photo-1551717743-49959800b1f6?w=500&h=340&fit=crop"],
    ["Brutus", "4 meses", "Macho", "https://images.unsplash.com/photo-1518717758536-85ae29035b6d?w=500&h=340&fit=crop"],
  ];

  static const List<List> usuarios = [
    ["Lucas Siqueira", "@lucas_siq", "https://media.licdn.com/dms/image/v2/D4D03AQFA2t10Xx7Ryg/profile-displayphoto-scale_200_200/B4DZyzsK6CGQAY-/0/1772541231367?e=2147483647&v=beta&t=Ibx53alkSHmeFX_kLbUu-5MLnQ1zvtBL7ziHrb6m_iE"],
    ["Cauã Araújo", "@araujocaua_", "https://media.licdn.com/dms/image/v2/D4D03AQFPfx8BI0NDLw/profile-displayphoto-scale_200_200/B4DaDyUEnrJUAg-/0/1790771743492?e=2147483647&v=beta&t=jMX651T_abIdiuVpQCgi_fKOd6H53irPGdDqXJCb_94"],
    ["Yasmim Pacheco", "@pachecoyasmim_", "https://media.licdn.com/dms/image/v2/D5603AQFip8uKvlGjlA/profile-displayphoto-shrink_200_200/B56ZYytw9KGcAc-/0/1744607582499?e=2147483647&v=beta&t=nceymyRACUWXw5j7Yq3Nu9WIiqjnM4FcxiIHCTBf0L4"],
  ];


  final TextEditingController pesquisaController = TextEditingController();

  String? pesquisa = "Pets";
  void mudarPesquisa(String estado) {
    setState(() {
      pesquisa = estado;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: pesquisaController,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                hintText: 'Pesquisar Pets, usuários ...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.cinza,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            SizedBox(height: 8,),
                
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => mudarPesquisa("Pets"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: pesquisa == "Pets"? AppColors.laranja : AppColors.rosa,
                      foregroundColor: pesquisa == "Pets"? Colors.white : AppColors.laranja,
                      elevation: 0,
                      fixedSize: const Size(double.infinity, 50),                   
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.pets,size: 26),
                        SizedBox(width: 10),
                        Text(
                          'Pets',
                          style: TextStyle(
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(width: 8,),

                Expanded(
                  child: ElevatedButton(
                    onPressed: () => mudarPesquisa("Usuários"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: pesquisa == "Usuários"? AppColors.laranja : AppColors.rosa,
                      foregroundColor: pesquisa == "Usuários"? Colors.white : AppColors.laranja,
                      elevation: 0,                
                      fixedSize: const Size(double.infinity, 50), 
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline_rounded, size: 26,),
                        SizedBox(width: 10),
                        Text(
                          'Usuários',
                          style: TextStyle(
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              ],
            ),

            SizedBox(height: 20,),

            Container(
              child: pesquisa == "Pets"
              ? Expanded(
                child: animais.isEmpty
                ? const Center(child: Text('Nenhum Animal Cadastrado'))
                : ListView.builder(
                  itemCount: animais.length,
                  itemBuilder: (context, index) {
                    final item = animais[index];

                    return _SearchCard(
                      name: item[0], 
                      desc: "${item[1]} - ${item[2]}", 
                      image: item[3], 
                      page: FichaAnimalScreen()
                    );

                  },
                ),
              )
              : Expanded(
                child: usuarios.isEmpty
                ? const Center(child: Text('Nenhum usuário Cadastrado'))
                : ListView.builder(
                  itemCount: usuarios.length,
                  itemBuilder: (context, index) {
                    final item = usuarios[index];

                    return _SearchCard(
                      name: item[0], 
                      desc: item[1], 
                      image: item[2], 
                      page: FichaPerfilScreen()
                    );

                  },
                ),
              ),
            ),
            

          ],
        ),
      ),
    );
  }
}
class _SearchCard extends StatelessWidget {
  const _SearchCard({
    required this.name,
    required this.desc,
    required this.image,
    required this.page
  });

  final String name;
  final String desc;
  final String image;
  final StatelessWidget page;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => page,
          ),
        );
      },
      child: Container(
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(image),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(fontSize: 20),
                      ),
                      Text(
                        desc,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.cinzaEscuro,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.laranja,
                  size: 26,
                ),
              ],
            ),
            const Divider(
              color: Colors.grey,
              thickness: 1,
            ),
          ],
        ),
      ),
    );
  }
}