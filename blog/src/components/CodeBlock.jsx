import { Highlight, themes } from 'prism-react-renderer';

const LANG_ALIASES = { gdscript: 'python' };

export default function CodeBlock({ className, children, ...props }) {
  const match = /language-(\w+)/.exec(className || '');
  if (!match) {
    return (
      <code className={className} {...props}>
        {children}
      </code>
    );
  }
  const lang = LANG_ALIASES[match[1]] || match[1];
  const code = String(children).replace(/\n$/, '');
  return (
    <Highlight theme={themes.vsDark} code={code} language={lang}>
      {({ tokens, getLineProps, getTokenProps }) => (
        <code style={{ display: 'block' }}>
          {tokens.map((line, i) => (
            <div key={i} {...getLineProps({ line })}>
              {line.map((token, key) => (
                <span key={key} {...getTokenProps({ token })} />
              ))}
            </div>
          ))}
        </code>
      )}
    </Highlight>
  );
}
