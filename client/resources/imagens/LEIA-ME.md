# imagens

PNG que entram no `assentamento` como estampa, por `tools/por_imagem.gd`.

O Godot so ve o que importou, entao sao dois passos e nao um:

```sh
cp a_minha.png client/resources/imagens/
godot --headless --path client --import
```

Alfa e respeitado — o que for transparente no PNG fica transparente na
cena. Uma imagem com fundo branco fica um retangulo branco no escuro.
