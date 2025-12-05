import { Button } from '@affine/component';

import * as styles from './animate-in-tooltip.css';

interface AnimateInTooltipProps {
  onNext: () => void;
  visible?: boolean;
}

export const AnimateInTooltip = ({
  onNext,
  visible,
}: AnimateInTooltipProps) => {
  return (
    <>
      <div className={styles.tooltip}>
        PLGames brings docs, whiteboards, and tasks together <br />
        so your ideas can level up faster.
      </div>
      <div className={styles.next}>
        {visible ? (
          <Button variant="primary" size="extraLarge" onClick={onNext}>
            Next
          </Button>
        ) : null}
      </div>
    </>
  );
};
