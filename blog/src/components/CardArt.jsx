import { useEffect, useState } from 'react';
import { stillFromGif } from '../gifFirstFrame.js';

export default function CardArt({ image, gif, active }) {
  const [still, setStill] = useState(image || null);

  useEffect(() => {
    if (image) {
      setStill(image);
      return;
    }
    if (!gif) {
      setStill(null);
      return;
    }
    let dead = false;
    stillFromGif(gif).then((url) => {
      if (!dead && url) setStill(url);
    });
    return () => {
      dead = true;
    };
  }, [image, gif]);

  return (
    <div className="post-card-art">
      {still && <img className="post-card-still" src={still} alt="" />}
      {gif && active && <img className="post-card-gif" src={gif} alt="" />}
    </div>
  );
}
