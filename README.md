# Ruínas Perdidas

Projeto Android desenvolvido com Godot.

## Envio dos arquivos do projeto

Este repositório será usado para receber os arquivos completos do projeto.

1. Abra a aba **Code** deste repositório.
2. Toque em **Add file** e depois em **Upload files**.
3. Selecione os arquivos e pastas do projeto ou envie um arquivo ZIP.
4. Aguarde o envio terminar e toque em **Commit changes**.

Depois que os arquivos forem enviados, poderemos organizar o projeto e configurar a compilação do APK para Android.

## Estado atual

Repositório inicializado. Os arquivos do jogo ainda precisam ser enviados.

## Mapa original de Guarapari

O mapa original da Rua Bela Vista é fornecido como um arquivo ZIP separado por causa do tamanho do GLB (aprox. 72,5 MB). Para habilitar o mapa no APK:

1. Abra a página de Releases: https://github.com/Pedra12/Ruinas-Perdidas-Android/releases/tag/V1.0.0
2. Edite a release V1.0.0 e anexe o arquivo `rua-bela-vista-29214-100-guarapari-sol-nascente-glb.zip` (aprox. 29 MB).
3. O ZIP deve conter o GLB `rua-bela-vista-29214-100-guarapari-sol-nascente.glb`, `miniskylines_attribution.txt`, `miniskylines_sources.json` e `README.txt`.
4. Execute os workflows **Validar projeto Godot e importar assets reais** e depois **Compilar APK Android**.

Os workflows baixam o ZIP da release, instalam o GLB em `RuinasPerdidas/assets/maps/` e preservam os arquivos de atribuição. O APK só será considerado com mapa integrado depois que a validação confirmar esse arquivo e a compilação concluir.