# Dictado por voz en español con voxtype + Groq

Dictado en cualquier app: mantienes una tecla, hablas y el texto aparece donde
está el cursor, limpio y bien puntuado. Funciona en macOS y en Linux.

```
tecla ─► voxtype graba ─► Groq Whisper large-v3 ─► normalizador (LLM en Groq) ─► sustituciones ─► texto en el cursor
                               ▲                          ▲                          ▲
                               └──────── vocabulary.txt ──┴── voxtype-vocab ─────────┘
                                         (lo amplía tu agente de IA cuando detecta una palabra mal transcrita)
```

- **Transcripción**: Whisper large-v3 en Groq, con el plan gratuito.
- **Normalizador** (`normalize-es.sh`): un LLM en Groq quita muletillas («eh», «o sea»,
  repeticiones), corrige puntuación y tildes, y escribe los términos de tu vocabulario como toca.
  Si falla, voxtype escribe el texto sin limpiar.
- **Diccionario que aprende** (`voxtype-vocab` + skill `dictation-vocabulary`): cuando tu
  agente de IA ve que el dictado ha destrozado un nombre («lum» por Loom), lo registra sin
  preguntarte. La próxima vez sale bien.

Cada persona empieza con un vocabulario mínimo y genérico, que va creciendo con su uso.

### ¿Hace falta una cuenta de Groq?

**No, es opcional, pero sí recomendable.** voxtype puede transcribir en tu propio ordenador.
Groq es un servicio en la nube con un plan gratuito que mejora bastante el resultado:

| | Con Groq (recomendado) | Sin Groq (`--local`) |
|---|---|---|
| Cuenta | Gratuita en console.groq.com | Ninguna |
| Transcripción | Whisper large-v3 en la nube: rápida y precisa en cualquier ordenador | Modelo Whisper en tu máquina: la calidad y la velocidad dependen del modelo y del ordenador |
| Limpieza del texto (muletillas, repeticiones, puntuación) | Sí, con un LLM en Groq | No: el texto sale tal cual lo transcribe Whisper |
| Diccionario que aprende | Sí: pista para Whisper, sustituciones y normalizador | Sí: pista para Whisper y sustituciones |
| Privacidad | El audio y el texto se envían a Groq | Nada sale de tu ordenador |
| Sin conexión | No funciona | Funciona |

Puedes empezar sin cuenta y pasarte a Groq más adelante con solo volver a ejecutar
`./install.sh` (sin `--local`), o al revés.

| Fichero | Qué es |
|---|---|
| `install.sh` | Instalador. Se puede volver a ejecutar sin problema: hace copia de `config.toml` y conserva tu vocabulario |
| `normalize-es.sh` | Post-proceso de voxtype que limpia el texto con Groq |
| `vocabulary.txt` | Vocabulario inicial (solo se copia si no tienes uno) |
| `skills/dictation-vocabulary/` | Skill para tu agente y el script `voxtype-vocab` |
| `AGENTS-snippet.md` | La regla que hay que añadir a las instrucciones globales de tu agente |

> **Estado:** probado en Linux (Arch + Hyprland, voxtype 1.3.1). En **macOS está escrito para
> funcionar, pero no se ha probado en un Mac real**. Si algo no cuadra, el agente debe mirar
> `voxtype config schema` y la documentación de voxtype antes de improvisar.

---

## Para agentes de IA

Si eres un agente instalando esto para tu usuario, sigue estos pasos en orden. Cada paso tiene
un criterio de éxito: no pases al siguiente sin cumplirlo. Al terminar, haz un resumen al usuario.

**Reglas**

- **Nunca pidas, leas ni escribas la API key de Groq en el chat.** La persona la pega en su
  propia terminal (paso 4).
- No edites `~/.config/voxtype/config.toml` a mano. Usa `install.sh` o `voxtype config set`.
  Nunca uses `voxtype config unset text.replacements.<x>`: borra todas las sustituciones.
- Los pasos que dependen de la interfaz de macOS (asistente, permisos, tecla) no están
  verificados. Compruébalos con `voxtype config schema` y `voxtype config get` y, si algo no
  coincide, díselo a la persona en vez de inventar claves.

**0. Preguntar a la persona si quiere usar Groq**

Explícale en dos líneas la tabla «¿Hace falta una cuenta de Groq?»: Groq es opcional, gratuito
y recomendable (mejor transcripción y limpieza del texto); sin Groq todo se queda en su
ordenador pero el texto sale sin limpiar. Recomienda Groq salvo que le preocupe la privacidad
o quiera dictar sin conexión.

✔ Sabes si la instalación es **con Groq** o **local**. En modo local, sáltate el paso 4.

**1. Clonar el repo**

```bash
git clone https://github.com/almaro90/voxtype-dictado.git ~/voxtype-dictado
cd ~/voxtype-dictado
```

✔ Existe `~/voxtype-dictado/install.sh`.

**2. Instalar voxtype y completar su asistente**

- macOS 13 o superior, con [Homebrew](https://brew.sh):
  ```bash
  brew install --cask peteonrails/voxtype/voxtype
  ```
  Después pide a la persona que abra voxtype (o ejecute `voxtype configure`) y complete el
  asistente: permisos de **Micrófono**, **Accesibilidad** y **Monitorización de entrada** en
  Ajustes del Sistema → Privacidad y seguridad, y la tecla de dictado (por defecto FN). Si no
  quiere usar FN, `hotkey.key` admite F13–F20 en macOS.
- Linux: sigue https://voxtype.io (paquete de tu distro y `voxtype setup`).

✔ Existe `~/.config/voxtype/config.toml` y `voxtype status` responde (por ejemplo, `idle`).
Si la config está en `~/Library/Application Support/voxtype`, avisa a la persona: las
versiones actuales usan `~/.config/voxtype`.

**3. Ejecutar el instalador**

```bash
./install.sh            # con Groq
./install.sh --local    # sin Groq
```

Instala `jq` y un Python 3.11 o superior si faltan (en macOS, con brew). También copia el
normalizador y el vocabulario, instala la skill en `~/.agents/skills/dictation-vocabulary`
(enlazada en `~/.claude/skills` si existe `~/.claude`), crea `~/.local/bin/voxtype-vocab` y
configura voxtype con `voxtype config set`. Con Groq, como tu terminal no es interactiva, te
avisará de que falta la key: es lo esperado. En modo local usa el modelo que descargó el
asistente de voxtype (`voxtype info models` muestra los instalados) y no activa el normalizador.

✔ Acaba con «Hecho.». Si avisa de que `~/.local/bin` no está en el PATH, añádelo al
`~/.zshrc` (macOS) o `~/.bashrc` de la persona.

**4. API key de Groq (lo hace la persona; solo con Groq)**

Pídele que:

1. Entre en https://console.groq.com, cree una cuenta gratuita y genere una key en
   https://console.groq.com/keys.
2. Ejecute **en su propia terminal** (no en tu chat):
   ```bash
   ~/voxtype-dictado/install.sh --key
   ```
   y pegue la key cuando se la pida. No se verá al escribirla.

✔ El script imprime «Groq responde: …» con una frase limpia.

**5. Dar la skill a tu agente**

- Claude Code lee `~/.claude/skills`; el instalador ya la ha enlazado ahí.
- Otros agentes: comprueba en su documentación de qué carpeta leen las skills. Si no es
  `~/.agents/skills`, crea un enlace simbólico a `~/.agents/skills/dictation-vocabulary`.

✔ Tu agente encuentra la skill `dictation-vocabulary`.

**6. Añadir la regla a las instrucciones globales del agente**

Añade el contenido de `AGENTS-snippet.md` al fichero de instrucciones globales del agente que
usa la persona (por ejemplo `~/.claude/CLAUDE.md` en Claude Code, o el `AGENTS.md` global de tu
agente). Sin esta regla el agente no sabrá que tiene que aprender palabras nuevas.

✔ La regla aparece una sola vez en ese fichero.

**7. Comprobar**

```bash
voxtype-vocab list   # contexto, vocabulario y sustituciones
for k in whisper.mode whisper.remote_endpoint whisper.remote_model whisper.language output.post_process.command; do
  printf '%s = ' "$k"; voxtype config get "$k"
done
```

Esperado con Groq: `remote`, `https://api.groq.com/openai`, `whisper-large-v3`, `es` y la
ruta a `normalize-es.sh`. En modo local: `whisper.mode` es `local`, `whisper.language` es `es`
y `output.post_process.command` sale vacío. No ejecutes `voxtype config get` sin clave: imprime la API key.

Pide a la persona que dicte una frase con la tecla en cualquier campo de texto.

✔ El texto aparece escrito y puntuado. Si no aparece nada en macOS, casi siempre faltan los
permisos de Accesibilidad o Monitorización de entrada: después de darlos, reinicia voxtype.

**8. Resumen para la persona**

Dile qué se ha instalado, dónde está la copia de `config.toml` (`config.toml.bak-*`), qué
pasos ha hecho ella, y que puede editar la línea `# contexto:` de `vocabulary.txt` si no
habla de desarrollo de software (sección «Personalizar»). Si pide otro modelo, proveedor o
reglas para la limpieza del texto, sigue «Personalizar el normalizador»: se hace con ficheros
en `~/.config/voxtype/`, nunca editando `normalize-es.sh`, porque `install.sh` lo sobrescribe.

---

## Para humanos

### 1. Cuenta de Groq (opcional, recomendada)

Si prefieres no crear cuenta, sáltate este paso y usa `./install.sh --local` en el paso 3.
Las diferencias están en la tabla «¿Hace falta una cuenta de Groq?».

1. Regístrate en https://console.groq.com.
2. En **API Keys** (https://console.groq.com/keys), crea una key y cópiala. Empieza por `gsk_`.

El plan gratuito tiene límites de peticiones y de minutos de audio
(https://console.groq.com/docs/rate-limits). Para dictar mensajes suele sobrar. Si un día los
superas, voxtype dará error hasta que se renueve el cupo.

### 2. Instalar voxtype

**macOS** (13 Ventura o superior):

```bash
brew install --cask peteonrails/voxtype/voxtype
```

Abre voxtype y sigue el asistente. Tendrás que dar permisos de **Micrófono**,
**Accesibilidad** y **Monitorización de entrada** en Ajustes del Sistema → Privacidad y
seguridad, y elegir la tecla de dictado.

**Linux**: sigue https://voxtype.io.

### 3. Instalar este flujo

```bash
git clone https://github.com/almaro90/voxtype-dictado.git ~/voxtype-dictado
cd ~/voxtype-dictado
./install.sh            # con Groq
./install.sh --local    # sin Groq
```

Con Groq, pega la key cuando te la pida. Al final verás una frase de prueba limpiada por Groq.

### 4. Usarlo

Mantén pulsada la tecla, habla y suelta. El texto se escribe donde esté el cursor.

### 5. El diccionario

Si usas un agente de IA (Claude Code, Codex…), añade a sus instrucciones globales la regla de
`AGENTS-snippet.md`. Cuando dictes algo y salga mal un nombre, el agente lo apuntará solo y te
lo dirá en una línea. También puedes hacerlo tú:

```bash
voxtype-vocab add "Loom" --heard "lum"             # «lum» se cambiará siempre por Loom
voxtype-vocab add "Claude" --heard "cloud" --no-replace   # solo como pista, porque «cloud» es una palabra real
voxtype-vocab list                                  # ver lo aprendido
voxtype-vocab undo                                  # deshacer lo último
```

El vocabulario está en `~/.config/voxtype/vocabulary.txt`, el más nuevo primero.

### Personalizar

- **De qué sueles hablar**: edita la línea `# contexto: desarrollo de software` de
  `~/.config/voxtype/vocabulary.txt` (por ejemplo, `# contexto: pediatría y educación
  infantil`) y ejecuta `voxtype-vocab sync`. La usan tanto Whisper como el normalizador.
- **Desactivar la limpieza**: `voxtype config unset output.post_process.command`.
- **Reactivarla** (por ejemplo, tras instalar con `--local`):
  `voxtype config set output.post_process.command ~/.config/voxtype/normalize-es.sh`.

### Personalizar el normalizador (el LLM que limpia el texto)

Después de transcribir, `normalize-es.sh` manda el texto a un LLM que quita muletillas, pone
la puntuación y escribe bien los términos del vocabulario. Por defecto usa
`openai/gpt-oss-20b` en Groq con la misma key que la transcripción. Todo se cambia con
ficheros en `~/.config/voxtype/`, sin tocar el script. Las variables de entorno no sirven,
porque voxtype no hereda las de tu terminal.

**Modelo y proveedor**: crea `~/.config/voxtype/normalize.env`. Vale cualquier API compatible
con la de chat completions de OpenAI.

```bash
# Otro modelo de Groq (lista en https://console.groq.com/docs/models)
NORMALIZE_MODEL=openai/gpt-oss-120b

# OpenRouter, OpenAI u otro proveedor: endpoint completo y su propia key
# NORMALIZE_ENDPOINT=https://openrouter.ai/api/v1/chat/completions
# NORMALIZE_MODEL=<proveedor/modelo>
# NORMALIZE_API_KEY=<tu key de ese proveedor>

# Un LLM en tu propio ordenador con Ollama: sin key y sin que salga nada de tu máquina
# NORMALIZE_ENDPOINT=http://localhost:11434/v1/chat/completions
# NORMALIZE_MODEL=llama3.2
# NORMALIZE_TIMEOUT=20

# Esfuerzo de razonamiento: "low" por defecto con los modelos gpt-oss; vacío lo desactiva
# NORMALIZE_REASONING_EFFORT=low
```

Si pones una key, protege el fichero con `chmod 600 ~/.config/voxtype/normalize.env`.

**Tiempo de espera**: `NORMALIZE_TIMEOUT` (7 s por defecto) es lo que el script espera al LLM.
Si lo subes, sube también el de voxtype para que no corte antes, siempre un segundo por
encima: `voxtype config set output.post_process.timeout_ms 21000`. Si el LLM no contesta a
tiempo, voxtype escribe el texto sin limpiar.

**Reglas propias**: escribe una regla por línea en `~/.config/voxtype/normalize-rules.txt`.
Se añaden al final del prompt y mandan sobre las de serie. Por ejemplo:

```
- Escribe los números siempre en cifras.
- Usa «tú», nunca «usted».
- Cuando diga «punto y aparte», pon un salto de línea.
```

**Prompt completo**: si quieres sustituir todas las reglas, escribe tu prompt en
`~/.config/voxtype/normalize-prompt.txt`, partiendo del que hay en `normalize-es.sh`.
`__CONTEXT__` se cambia por la línea `# contexto:` de tu vocabulario. El vocabulario conocido
y las reglas propias se siguen añadiendo al final.

**Probar un cambio** sin dictar:

```bash
echo "eh bueno pues mañana a las cinco o sea revisamos el el informe" | ~/.config/voxtype/normalize-es.sh; echo
```

Si da un error o no imprime nada, revisa la conexión, la key, el endpoint y el nombre del modelo. Los cambios en estos
ficheros se aplican en el siguiente dictado, sin reiniciar voxtype.

### Privacidad

Con Groq, el audio y el texto se envían a Groq: no dictes nada que no mandarías a un servicio
externo. Con `./install.sh --local` no sale nada de tu ordenador.

La key se guarda en `~/.config/voxtype/config.toml` con permisos 600. Si sincronizas tus
dotfiles (chezmoi, git…), no subas ese fichero a un repo público.

### Problemas frecuentes

| Síntoma | Causa probable |
|---|---|
| No se escribe nada (macOS) | Faltan permisos de Accesibilidad o Monitorización de entrada. Dalos y reinicia voxtype |
| Sale texto sin puntuar ni limpiar | Ha fallado el normalizador: key, conexión o límite de Groq. Prueba `echo "hola eh que tal" \| ~/.config/voxtype/normalize-es.sh` |
| `voxtype-vocab: necesita Python 3.11` | `brew install python` y vuelve a ejecutar `./install.sh` |
| `voxtype-vocab: command not found` | Añade `~/.local/bin` al PATH |
| Un cambio del diccionario no se aplica | `voxtype-vocab restart`, o cierra y abre voxtype |

### Actualizar y desinstalar

- Actualizar: `cd ~/voxtype-dictado && git pull && ./install.sh`.
- Desinstalar el flujo: borra `~/.agents/skills/dictation-vocabulary`,
  `~/.claude/skills/dictation-vocabulary`, `~/.local/bin/voxtype-vocab` y
  `~/.config/voxtype/normalize-es.sh`, y restaura un `config.toml.bak-*`. Para quitar voxtype
  en macOS: `brew uninstall --cask voxtype`.
