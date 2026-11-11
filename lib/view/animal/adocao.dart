import 'package:flutter/material.dart';
import '../core/app_colors.dart';

import '../usuario/fichaPerfil.dart';

class AdocaoScreen extends StatelessWidget {
  const AdocaoScreen({super.key});

  final String status = "Aguardando";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Adoção ID#187241946'),
        shape: const Border(
          bottom: BorderSide(
            color: Color(0xFFD96C3F),
            width: 2,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [

            Row(
              mainAxisAlignment: MainAxisAlignment.start, // 👈 Alinha os elementos para a esquerda
              children: [
                Text(
                  "Solicitação de Adoção",
                  style: TextStyle(
                    fontSize: 24
                  ),
                ),
              ],
            ),

            Row(
              children: [
                Expanded(
                  child: Text(
                    'Confira as informações sobre a adoção do Bolt.',
                    style: TextStyle(fontSize: 18, color: AppColors.cinzaEscuro),
                    softWrap: true,
                  ),
                ),
              ],
            ),

            SizedBox(height: 20,),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              decoration: BoxDecoration(
                color: AppColors.rosaClaro,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  SizedBox(
                    width: 120 * (4 / 3), // 80 pixels de largura calculados pelo 4/3
                    height: 120,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6.0), 
                      child: Image.network(
                        'https://images.unsplash.com/photo-1583511655857-d19b40a7a54e?w=500&h=340&fit=crop',
                        fit: BoxFit.cover, 
                      ),
                    ),
                  ),

                  SizedBox(width: 8,),
                  
                  Expanded(
                    child: Column(
                      children: [

                        Row(
                          mainAxisAlignment: MainAxisAlignment.start, // 👈 Alinha os elementos para a esquerda
                          children: [
                            Text(
                              "Nome do animal",
                              style: TextStyle(
                                fontSize: 24
                              ),
                            ),
                          ],
                        ),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.start, // 👈 Alinha os elementos para a esquerda
                          children: [
                            Text(
                              "1 ano - Macho",
                              style: TextStyle(
                                fontSize: 14
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 4,),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.start, // 👈 Alinha os elementos para a esquerda
                          children: [
                            Icon(Icons.location_on_outlined, size: 18, color: AppColors.laranja,),
                            Text(
                              "Mogi das Cruzes",
                              style: TextStyle(
                                fontSize: 14
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 4,),

                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                            decoration: BoxDecoration(
                              color: AppColors.verdeClaro,
                              borderRadius: BorderRadius.circular(30),
                            ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.pets, color: AppColors.verde,),
                              SizedBox(width: 10,),
                              Text("90% de Compatibilidade", style: TextStyle(color: AppColors.verde),),
                            ],
                          ),
                        ),

                      ],
                    )
                  ),
                  
                ],
              )

            ),
            
            SizedBox(height: 20,),    

            Row(
              mainAxisAlignment: MainAxisAlignment.start, // 👈 Alinha os elementos para a esquerda
              children: [
                Text(
                  "Publicado por: ",
                  style: TextStyle(
                    fontSize: 24
                  ),
                ),
              ],
            ),

            SizedBox(height: 10,),

            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FichaPerfilScreen(),
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
                          backgroundImage: NetworkImage("https://media.licdn.com/dms/image/v2/D4D03AQFA2t10Xx7Ryg/profile-displayphoto-scale_200_200/B4DZyzsK6CGQAY-/0/1772541231367?e=2147483647&v=beta&t=Ibx53alkSHmeFX_kLbUu-5MLnQ1zvtBL7ziHrb6m_iE"),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Lucas Siqueira",
                                style: const TextStyle(fontSize: 20),
                              ),
                              Text(
                                "@lucas_siq",
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
                    
                  ],
                ),
              ),
            ),

            SizedBox(height: 20,),    

            Row(
              mainAxisAlignment: MainAxisAlignment.start, // 👈 Alinha os elementos para a esquerda
              children: [
                Text(
                  "Seus dados: ",
                  style: TextStyle(
                    fontSize: 24
                  ),
                ),
              ],
            ),

            SizedBox(height: 10,),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.rosaClaro,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Icon(Icons.person_outlined, size: 22,),
                          SizedBox(width: 4,),
                          Text(
                            "Nome: Nome do Perfil",
                            style: TextStyle(
                              fontSize: 18
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 4,),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Icon(Icons.mail_outline, size: 22,),
                          SizedBox(width: 4,),
                          Text(
                            "E-mail: exemplo@email.com",
                            style: TextStyle(
                              fontSize: 18
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 4,),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Icon(Icons.phone_outlined, size: 22,),
                          SizedBox(width: 4,),
                          Text(
                            "Telefone: (11) 98765-4321",
                            style: TextStyle(
                              fontSize: 18
                            ),
                          ),
                        ],
                      ),
                      
                    ],
                  ),
                  
                ],
              ),

            ),

            SizedBox(height: 20,),    

            Row(
              mainAxisAlignment: MainAxisAlignment.start, // 👈 Alinha os elementos para a esquerda
              children: [
                Text(
                  "Informações da Solicitação: ",
                  style: TextStyle(
                    fontSize: 24
                  ),
                ),
              ],
            ),

            SizedBox(height: 10,),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.rosaClaro,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Icon(Icons.calendar_month_outlined, size: 22,),
                          SizedBox(width: 4,),
                          Text(
                            "Data: 31/03/2007",
                            style: TextStyle( 
                              fontSize: 18
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 4,),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Icon(Icons.timer_outlined, size: 22,),
                          SizedBox(width: 4,),
                          Text(
                            "Hora: 15:30",
                            style: TextStyle(
                              fontSize: 18
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 4,),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Icon(Icons.hourglass_bottom, size: 22,),
                          SizedBox(width: 4,),
                          Text(
                            "Status: ",
                            style: TextStyle(
                              fontSize: 18
                            ),
                          ),

                          Text(
                            status,
                            style: TextStyle(
                              fontSize: 18,
                              color: status == "Aceito" ? Colors.green[800] : status == "Aguardando" ? Colors.amber[900] : Colors.red,
                            ),
                          ),
                        ],
                      ),
                      
                    ],
                  ),
                  
                ],
              )
            ), 

            SizedBox(height: 20,),

            SizedBox(
              height: 62,
              child: ElevatedButton(
                onPressed: () {
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (context) => const EditarPerfilScreen(),
                  //   ),
                  // );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.laranja,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.edit_note_rounded, size: 24),
                    SizedBox(width: 10),
                    Text('Editar Perfil', style: TextStyle(fontSize: 24)),
                  ],
                ),
              ),
            ),

          ]
        ),
      ),
    );
  }

}