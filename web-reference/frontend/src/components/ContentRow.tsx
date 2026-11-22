import React, { useRef, useState } from 'react';
import { ChevronLeft, ChevronRight } from 'lucide-react';
import { MediaItem } from '../types';
import { MediaCard } from './MediaCard';

interface ContentRowProps {
  title: string;
  items: MediaItem[];
  isTop10?: boolean;
}

const Top10Number: React.FC<{ rank: number }> = ({ rank }) => {
  return (
    <div className="relative h-[95px] sm:h-[115px] md:h-[135px] w-14 sm:w-16 md:w-20 flex-none select-none -mr-3 sm:-mr-4 z-0 pointer-events-none flex items-end justify-center">
      <svg
        className="w-full h-full overflow-visible"
        viewBox={rank === 10 ? "0 0 120 140" : "0 0 80 140"}
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
      >
        <text
          x="50%"
          y="85%"
          textAnchor="middle"
          fill="#141414"
          stroke="#595959"
          strokeWidth="6"
          style={{
            fontFamily: 'Impact, "Arial Black", -apple-system, sans-serif',
            fontWeight: 900,
            fontSize: '135px',
            letterSpacing: '-6px',
            paintOrder: 'stroke fill'
          }}
        >
          {rank}
        </text>
      </svg>
    </div>
  );
};

export const ContentRow: React.FC<ContentRowProps> = ({ title, items, isTop10 }) => {
  const rowRef = useRef<HTMLDivElement>(null);
  const [showLeftArrow, setShowLeftArrow] = useState(false);
  const [showRightArrow, setShowRightArrow] = useState(true);

  if (!items || items.length === 0) return null;

  const handleScroll = (direction: 'left' | 'right') => {
    if (rowRef.current) {
      const { scrollLeft, clientWidth } = rowRef.current;
      const scrollAmount = clientWidth * 0.75;
      const newScrollLeft = direction === 'left' ? scrollLeft - scrollAmount : scrollLeft + scrollAmount;

      rowRef.current.scrollTo({
        left: newScrollLeft,
        behavior: 'smooth'
      });
    }
  };

  const onScroll = () => {
    if (rowRef.current) {
      const { scrollLeft, scrollWidth, clientWidth } = rowRef.current;
      setShowLeftArrow(scrollLeft > 20);
      setShowRightArrow(scrollLeft < scrollWidth - clientWidth - 20);
    }
  };

  return (
    <div className="relative group my-4 sm:my-6 md:my-8 px-4 md:px-12 select-none hover:z-40 transition-[z-index]">
      {/* Row Header */}
      <div className="flex items-baseline justify-between mb-2 sm:mb-3">
        <h2 className="text-base sm:text-lg md:text-xl font-bold text-[#E5E5E5] hover:text-white transition-colors cursor-pointer flex items-center space-x-2">
          <span>{title}</span>
          <span className="text-xs text-[#E50914] opacity-0 group-hover:opacity-100 transition-opacity font-normal">
            Explore All ›
          </span>
        </h2>
      </div>

      {/* Relative Carousel Container */}
      <div className="relative">
        {/* Left Arrow Button */}
        {showLeftArrow && (
          <button
            onClick={() => handleScroll('left')}
            className="absolute left-0 top-0 bottom-0 z-30 w-10 sm:w-12 bg-black/60 hover:bg-black/85 text-white flex items-center justify-center opacity-0 group-hover:opacity-100 transition-all rounded-r"
            aria-label="Scroll Left"
          >
            <ChevronLeft className="w-8 h-8 transform group-hover:scale-125 transition-transform" />
          </button>
        )}

        {/* Scrollable Container with responsive clearance (clean on mobile touch, hover clearance on desktop) */}
        <div
          ref={rowRef}
          onScroll={onScroll}
          className="flex items-center space-x-2 sm:space-x-3 overflow-x-auto no-scrollbar scroll-smooth px-1 sm:px-2 py-2 md:pt-[75px] md:pb-[135px] md:-mt-[75px] md:-mb-[135px]"
        >
          {items.map((item, idx) => {
            if (isTop10) {
              return (
                <div key={item.id} className="relative flex items-center flex-none group/top10">
                  <Top10Number rank={idx + 1} />
                  <MediaCard 
                    item={item} 
                    rank={idx + 1} 
                    index={idx} 
                    totalItems={items.length} 
                  />
                </div>
              );
            }
            return (
              <MediaCard 
                key={item.id} 
                item={item} 
                index={idx} 
                totalItems={items.length} 
              />
            );
          })}
        </div>

        {/* Right Arrow Button */}
        {showRightArrow && (
          <button
            onClick={() => handleScroll('right')}
            className="absolute right-0 top-0 bottom-0 z-30 w-10 sm:w-12 bg-black/60 hover:bg-black/85 text-white flex items-center justify-center opacity-0 group-hover:opacity-100 transition-all rounded-l"
            aria-label="Scroll Right"
          >
            <ChevronRight className="w-8 h-8 transform group-hover:scale-125 transition-transform" />
          </button>
        )}
      </div>
    </div>
  );
};
