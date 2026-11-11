import 'package:entre_patas/view/animal/adocao.dart';
import 'package:flutter/material.dart';
import '../core/app_colors.dart';

import '../usuario/fichaPerfil.dart';

class FichaAnimalScreen extends StatelessWidget {
  const FichaAnimalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('NOME DO ANIMAL'),
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

            AspectRatio(
              aspectRatio: 4 / 3, // Define a proporção (Largura / Altura)
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.0), // Bordas arredondadas
                child: Image.network(
                  'https://images.unsplash.com/photo-1583511655857-d19b40a7a54e?w=500&h=340&fit=crop',
                  fit: BoxFit.cover, // Garante que a imagem preencha todo o espaço sem distorcer
                ),
              ),
            ),

            SizedBox(height: 20,),

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppColors.rosa,
                      borderRadius: BorderRadius.circular(30),
                    ),
                  child: Row(
                    children: [
                      Icon(Icons.pets, color: AppColors.laranja,),
                      SizedBox(width: 10,),
                      Text("90% de Compatibilidade", style: TextStyle(color: AppColors.laranja),),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 10,),

            Row(
              mainAxisAlignment: MainAxisAlignment.start, // 👈 Alinha os elementos para a esquerda
              children: [
                Text(
                  "Nome do animal",
                  style: TextStyle(
                    fontSize: 28
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
            
            SizedBox(height: 20,),

            Row(
              mainAxisAlignment: MainAxisAlignment.start, // 👈 Alinha os elementos para a esquerda
              children: [
                Text(
                  "Sobre mim",
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
                    'Oi! Eu sou o Bolt! Sou um cachorrinho carinhoso, brincalhão e cheio de energia.  Adoro receber carinho, passear e estar perto das pessoas. Estou procurando uma família para compartilhar muitos momentos felizes!',
                    style: TextStyle(fontSize: 18, color: AppColors.cinzaEscuro),
                    softWrap: true,
                  ),
                ),
              ],
            ),

            SizedBox(height: 20,),

            Row(
              mainAxisAlignment: MainAxisAlignment.start, // 👈 Alinha os elementos para a esquerda
              children: [
                Text(
                  "Informações",
                  style: TextStyle(
                    fontSize: 24
                  ),
                ),
              ],
            ),

            SizedBox(height: 10,),
            
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              decoration: BoxDecoration(
                color: AppColors.rosaClaro,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Espécie:"),
                  Text("Cachorro", style: TextStyle(fontSize: 20),),
                ],
              )

            ),

            SizedBox(height: 8,),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppColors.rosaClaro,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Energia:"),
                        Text("Alta", style: TextStyle(fontSize: 20),),
                      ],
                    )

                  ),
                ),
                

                SizedBox(width: 8,),

                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppColors.rosaClaro,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Porte:"),
                        Text("Pequeno", style: TextStyle(fontSize: 20),),
                      ],
                    )

                  ),
                ),
              ],
            ),


            SizedBox(height: 8,),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppColors.rosaClaro,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Carência:"),
                        Text("Sim", style: TextStyle(fontSize: 20),),
                      ],
                    )

                  ),
                ),
                

                SizedBox(width: 8,),

                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppColors.rosaClaro,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Convivência:"),
                        Text("Sim", style: TextStyle(fontSize: 20),),
                      ],
                    )

                  ),
                ),
              ],
            ),

            SizedBox(height: 8,),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppColors.rosaClaro,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Vacinado:"),
                        Text("Sim", style: TextStyle(fontSize: 20),),
                      ],
                    )

                  ),
                ),
                

                SizedBox(width: 8,),

                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppColors.rosaClaro,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Castrado:"),
                        Text("Sim", style: TextStyle(fontSize: 20),),
                      ],
                    )

                  ),
                ),
              ],
            ),

            SizedBox(height: 20,),

            SizedBox(
              height: 62,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdocaoScreen(),
                    ),
                  );
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
                    Text('Quero Adotar', style: TextStyle(fontSize: 24)),
                    SizedBox(width: 10),
                    Icon(Icons.pets),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20,),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.start, // 👈 Alinha os elementos para a esquerda
              children: [
                Text(
                  "Compatibilidade",
                  style: TextStyle(
                    fontSize: 24
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                const Text(
                  "Rotina: 55%",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),

            const SizedBox(height: 6),
             // Espaço entre o texto e a barra
            ClipRRect(
              borderRadius: BorderRadius.circular(4), // Deixa as pontas da barra arredondadas
              child: const LinearProgressIndicator(
                value: 0.55, // 55% preenchido (valor vai de 0.0 a 1.0)
                minHeight: 12, // Altura/grossura da barra
                backgroundColor: Color(0xFFF0F0F0), // Cor do fundo cinza claro
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.laranja), // Cor laranja do preenchimento
              ),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                const Text(
                  "Ambiente: 100%",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),

            const SizedBox(height: 6),
             // Espaço entre o texto e a barra
            ClipRRect(
              borderRadius: BorderRadius.circular(4), // Deixa as pontas da barra arredondadas
              child: const LinearProgressIndicator(
                value: 1, // 55% preenchido (valor vai de 0.0 a 1.0)
                minHeight: 12, // Altura/grossura da barra
                backgroundColor: Color(0xFFF0F0F0), // Cor do fundo cinza claro
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.laranja), // Cor laranja do preenchimento
              ),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                const Text(
                  "Preferências: 75%",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),

            const SizedBox(height: 6),
             // Espaço entre o texto e a barra
            ClipRRect(
              borderRadius: BorderRadius.circular(4), // Deixa as pontas da barra arredondadas
              child: const LinearProgressIndicator(
                value: 0.75, // 55% preenchido (valor vai de 0.0 a 1.0)
                minHeight: 12, // Altura/grossura da barra
                backgroundColor: Color(0xFFF0F0F0), // Cor do fundo cinza claro
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.laranja), // Cor laranja do preenchimento
              ),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                const Text(
                  "Nota de Compatibilidade: 73%",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),

            const SizedBox(height: 6),
             // Espaço entre o texto e a barra
            ClipRRect(
              borderRadius: BorderRadius.circular(4), // Deixa as pontas da barra arredondadas
              child: const LinearProgressIndicator(
                value: 0.73, // 55% preenchido (valor vai de 0.0 a 1.0)
                minHeight: 12, // Altura/grossura da barra
                backgroundColor: Color(0xFFF0F0F0), // Cor do fundo cinza claro
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.verde), // Cor laranja do preenchimento
              ),
            ),

            SizedBox(height: 8,),
            Text("Nota = (Rotina*5 + Ambiente*3 + Preferências*2)/10", style: TextStyle(fontSize: 10, color: AppColors.cinzaEscuro),),

            SizedBox(height: 20,),

            const Divider(
              color: AppColors.laranja,
              thickness: 1,
            ),

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



          ]
        ),
      ),
    );
  }

}