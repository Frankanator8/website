import { useEffect, useRef } from 'react';
import { Canvas, useFrame } from '@react-three/fiber';
import { Stars } from '@react-three/drei';

const reduced =
  typeof window !== 'undefined' &&
  window.matchMedia('(prefers-reduced-motion: reduce)').matches;

function Drift({ children }) {
  const group = useRef();
  const scrollY = useRef(0);

  useEffect(() => {
    if (reduced) return;
    const onScroll = () => {
      scrollY.current = window.scrollY;
    };
    window.addEventListener('scroll', onScroll, { passive: true });
    return () => window.removeEventListener('scroll', onScroll);
  }, []);

  useFrame((_, delta) => {
    if (reduced || !group.current) return;
    group.current.rotation.y += delta * 0.008;
    const target = scrollY.current * 0.00015;
    group.current.rotation.x += (target - group.current.rotation.x) * 0.05;
  });

  return <group ref={group}>{children}</group>;
}

export default function StarfieldBackground() {
  return (
    <div className="bg-canvas" aria-hidden="true">
      <Canvas
        camera={{ position: [0, 0, 1] }}
        dpr={[1, 1.5]}
        gl={{ antialias: false, powerPreference: 'low-power' }}
      >
        <Drift>
          <Stars
            radius={80}
            depth={40}
            count={2500}
            factor={3}
            saturation={0}
            fade
            speed={reduced ? 0 : 0.5}
          />
        </Drift>
      </Canvas>
    </div>
  );
}
