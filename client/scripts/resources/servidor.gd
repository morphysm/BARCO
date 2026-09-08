## Onde o app fala com o servidor.
##
## Vive num `.tres` e nao em constantes dentro de um script para trocar de
## projecto ser trocar um ficheiro de dados, e nao mexer em codigo.
class_name Servidor
extends Resource

@export var url: String = ""
## A chave PUBLICA (anon). E publica por desenho: vai dentro do app,
## qualquer pessoa a consegue ler do executavel, e nao da acesso a nada —
## quem manda e o RLS, e as tabelas de dinheiro nao tem politica nenhuma.
##
## A chave de admin NUNCA entra aqui. Essa vive so nas Edge Functions, e
## e o servidor do Supabase que a injecta.
@export var chave_publica: String = ""
